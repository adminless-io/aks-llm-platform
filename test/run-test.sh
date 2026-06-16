#!/usr/bin/env bash
# e2e: validate the GitOps/Kustomize LOGIC on a kind cluster.
# Asserts: overlays build, base applies, Service gets endpoints, the rolling
# update is zero-downtime, and the PDB is in place. GPU/Spot/Azure are out of
# scope here (prod-like AKS gate — see BONUS.md).
set -euo pipefail

NS=llm
APP=llm-serving

echo "== 1. all overlays build cleanly =="
for d in gitops/apps/llm/base gitops/apps/llm/overlays/dev \
         gitops/apps/llm/overlays/prod gitops/argocd/apps test; do
  kubectl kustomize "$d" >/dev/null
  echo "   ok: $d"
done

echo "== 2. apply kind test overlay =="
kubectl apply -k test/

echo "== 3. deployment becomes available =="
kubectl -n "$NS" rollout status "deploy/$APP" --timeout=180s

echo "== 4. service has endpoints (selector is correct) =="
for _ in $(seq 1 30); do
  eps=$(kubectl -n "$NS" get endpoints "$APP" -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w | tr -d ' ')
  [ "$eps" -ge 2 ] && break
  sleep 2
done
[ "$eps" -ge 2 ] || { echo "FAIL: expected >=2 endpoints, got $eps"; exit 1; }
echo "   ok: $eps endpoints"

echo "== 5. PDB present =="
kubectl -n "$NS" get pdb "$APP" >/dev/null
echo "   ok"

echo "== 6. zero-downtime rolling update (0 failed requests) =="
kubectl -n "$NS" port-forward "svc/$APP" 18000:8000 >/tmp/pf.log 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
sleep 4
fails=0
( for _ in $(seq 1 120); do
    curl -fsS -o /dev/null "http://127.0.0.1:18000/health" || echo x >>/tmp/fail
    sleep 0.25
  done ) &
LOAD=$!
ROLLVAL="$(date +%s 2>/dev/null || echo r1)"
kubectl -n "$NS" set env "deploy/$APP" "ROLL=${ROLLVAL}" >/dev/null
kubectl -n "$NS" rollout status "deploy/$APP" --timeout=180s
wait $LOAD || true
[ -f /tmp/fail ] && fails=$(wc -l </tmp/fail | tr -d ' ')
echo "   failed requests during rollout: $fails"
[ "${fails:-0}" -eq 0 ] || { echo "FAIL: rollout was not zero-downtime"; exit 1; }

echo "ALL CHECKS PASSED"

<!-- Thanks for contributing to aks-llm-platform. Keep PRs scoped to one layer/concern. -->

## What & why

<!-- What does this change and why. Link issues: Closes #123 -->

## Layer / area

- [ ] `terraform/` (which layer: `__`)
- [ ] `gitops/`
- [ ] `scripts/` / CI
- [ ] docs

## Checklist

- [ ] `pre-commit run -a` passes (fmt, validate, tflint, checkov, yamllint, shellcheck)
- [ ] `terraform plan` is **clean (no diff)** on a second run for the touched layer
- [ ] No secrets / real subscription or tenant IDs committed
- [ ] Docs / README updated if behavior or variables changed
- [ ] `test/run-test.sh` (kind GitOps e2e) still passes for `gitops/` changes

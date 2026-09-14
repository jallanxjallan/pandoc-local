# Defaults

Place Pandoc defaults files (`*.yaml`, `*.json`) here.

`dispatch.yaml` is the permanent service dispatch configuration. The service
invokes it together with an ephemeral defaults file whose complete contract is:

```yaml
input-files:
  - /absolute/path/to/source.md
metadata:
  plan: plan.slug
```

`plan` is the sole canonical dispatch-plan metadata key.

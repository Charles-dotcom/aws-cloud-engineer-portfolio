# Infrastructure

`bootstrap` creates the state bucket, the lock table and the GitHub OIDC roles. `modules/workload` builds one environment. `environments/dev`, `staging` and `prod` are thin roots.

Validate without AWS:

```bash
make validate
```

Apply steps, cost and tear-down are in the [repository README](../README.md).

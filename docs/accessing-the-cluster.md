# Accessing the Kubernetes Cluster

Zeno runs on two EKS clusters in AWS account `084375562450` (part of WRI's AWS
Organization), region `us-east-1`:

| Environment | Cluster name | Deployed from |
|---|---|---|
| Staging | `zeno-staging-cluster` | `develop` branch |
| Production | `zeno-production-cluster` | `main` branch |

You need two things: AWS credentials for account `084375562450`, and an EKS
access entry for your principal. If `aws` commands work but `kubectl` returns
`Unauthorized`, you have the first but not the second — see
[Granting access](#granting-access-admins-only).

## 1. Install the tools

```bash
brew install awscli kubectl helm
```

Not on Homebrew? See [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html),
[kubectl](https://kubernetes.io/docs/tasks/tools/), [helm](https://helm.sh/docs/intro/install/).

Check:

```bash
aws --version
kubectl version --client
helm version
```

## 2. Authenticate to AWS

### Option A — SSO (preferred)

```bash
aws configure sso --profile zeno
```

Answer with:

| Prompt | Value |
|---|---|
| SSO session name | `wri` |
| SSO start URL | `<WRI_SSO_START_URL>` |
| SSO region | `us-east-1` |
| SSO registration scopes | `sso:account:access` (default) |
| Account | `084375562450` |
| Role | `AWSAdministratorAccess` |
| Default client region | `us-east-1` |

Ask an admin for the start URL, or find it in WRI's AWS access request process.

Then, and again whenever the session expires:

```bash
aws sso login --profile zeno
```

The `AWSAdministratorAccess` permission set already has cluster admin on both
clusters, so nothing further is needed on this path.

### Option B — IAM access keys

An admin creates you an IAM user in account `084375562450` and gives you an
access key pair. Then:

```bash
aws configure --profile zeno   # region: us-east-1, output: json
```

You will also need an access entry — see [Granting access](#granting-access-admins-only).

### Verify either way

```bash
aws sts get-caller-identity --profile zeno
```

The `Account` in the output must be `084375562450`.

## 3. Get a kubeconfig

`--alias` keeps the context names short; without it they default to the full
cluster ARN.

```bash
aws eks update-kubeconfig --region us-east-1 --name zeno-staging-cluster \
  --alias zeno-staging --profile zeno

aws eks update-kubeconfig --region us-east-1 --name zeno-production-cluster \
  --alias zeno-production --profile zeno
```

Switch between them and confirm:

```bash
kubectl config use-context zeno-staging
kubectl config current-context
kubectl get pods
```

> ⚠️ The scripts and runbooks in this repo (`whitelist-emails.sh`,
> `docs/clickhouse-disk-cleanup.md`) act on whatever context is currently
> selected and have no production guard. Run `kubectl config current-context`
> before anything destructive.

## 4. What's where

| Namespace | Contents |
|---|---|
| `default` | Zeno itself — `zeno-api`, `zeno-web`, `zeno-worker`, `zeno-shell`, `langfuse`, ClickHouse, pgbouncer |
| `support` | Grafana, Loki, Prometheus |
| `eoapi` | eoapi stack |
| `ingress-nginx` | NLB ingress controller |
| `cert-manager` | TLS certificate issuance |
| `kube-system` | cluster-autoscaler, EKS addons |

Commands you'll reach for most:

```bash
kubectl get pods                        # the Zeno app (default namespace)
kubectl logs -f deploy/zeno-api
kubectl exec -it deploy/zeno-api -- bash
kubectl get pods -n support             # Grafana / Loki / Prometheus
```

See the [README](../README.md) for the Grafana login and log-browsing steps, and
[clickhouse-disk-cleanup.md](./clickhouse-disk-cleanup.md) for an example runbook.

## Granting access (admins only)

Both clusters use EKS access entries. To add someone, run this once per cluster:

```bash
CLUSTER=zeno-staging-cluster   # then repeat with zeno-production-cluster
PRINCIPAL=arn:aws:iam::084375562450:user/NAME@developmentseed.org

aws eks create-access-entry --region us-east-1 \
  --cluster-name "$CLUSTER" --principal-arn "$PRINCIPAL"

aws eks associate-access-policy --region us-east-1 \
  --cluster-name "$CLUSTER" --principal-arn "$PRINCIPAL" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

Confirm:

```bash
aws eks list-access-entries --region us-east-1 --cluster-name "$CLUSTER"
```

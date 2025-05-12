# project-zeno-deploy

This repository contains the infrastructure and deployment configuration for the Zeno project.

## Deployment Process

The deployment process is automated through GitHub Actions:

- Pushing to `develop` branch triggers a deployment to staging environment
- Pushing to `main` branch triggers a deployment to production environment

## Environment URLs

- **Staging**: https://api.zeno-staging.ds.io
- **Production**: https://api.zeno.ds.io

## Updating Application Version

To update the application version:

1. Open `helm/zeno/values.yaml`
2. Under the `api` section, locate the `image` subsection
3. Update the `tag` field with the desired git hash from the main Zeno repository

Example:
```yaml
api:
  image:
    repository: public.ecr.aws/b7u8b0a6/project-zeno/zeno
    tag: 2757f359105a9738086f1d07ac2e8200cca9675d  # Replace with new git hash
```

## Database Updates

When the database schema or migrations have changed:

1. Open `helm/zeno/values.yaml`
2. Under the `db` section, locate the `image` subsection
3. Update the `tag` field with the git hash that includes the database changes

Example:
```yaml
db:
  image:
    repository: public.ecr.aws/b7u8b0a6/project-zeno/zeno-db
    tag: 149bffadbb4d58500b13accc7eb862c4d6d08150  # Replace with new git hash
```

Note: It's important to ensure that the database migrations are compatible with the application version being deployed.

## Testing

The project includes automated tests that can be run both locally and in CI, as well as manual verification tests for deployed environments.

### Running Tests Locally

Prerequisites:
- [k3d](https://k3d.io/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed
- [Helm](https://helm.sh/docs/intro/install/) installed

To run tests in a local k3d cluster:

1. Set up the test cluster and dependencies:
   ```bash
   ./helm/zeno/tests/ci/setup-cluster.sh
   ```
   This will:
   - Create a k3d cluster
   - Install ingress-nginx and cert-manager
   - Set up PostgreSQL for both Zeno and Langfuse
   - Install support services

2. Run the tests:
   ```bash
   ./helm/zeno/tests/ci/run-tests.sh
   ```
   This validates:
   - Deployment success
   - Pod health
   - Database migrations
   - API endpoints
   - Basic functionality

3. Clean up after testing:
   ```bash
   ./helm/zeno/tests/ci/cleanup.sh
   ```

### Post-Deployment Verification

To verify a deployment in staging or production:

1. First, verify your kubectl context:
   ```bash
   kubectl config current-context
   # Should show zeno-staging or zeno-production
   ```

2. Run the post-deployment verification:
   ```bash
   # For staging
   ./helm/zeno/tests/manual/post-deploy.sh staging
   
   # For production
   ./helm/zeno/tests/manual/post-deploy.sh production
   ```

The script will:
- Confirm you're using the correct cluster context
- Check infrastructure components (ingress, cert-manager)
- Verify application pods are healthy
- Test endpoints
- Check database migration status
- Scan logs for potential issues

### CI Testing

Tests run automatically on pull requests through GitHub Actions:

1. A k3d cluster is created for testing
2. Dependencies are installed:
   - ingress-nginx
   - cert-manager
   - PostgreSQL (for both Zeno and Langfuse)
   - Support services

3. Tests verify:
   - Helm chart installation
   - Pod health and readiness
   - Database migrations
   - API endpoint functionality

Test results are included in the PR comments along with the Terraform plan.

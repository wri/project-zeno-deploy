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

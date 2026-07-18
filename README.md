# @triskcraft/db

Canonical Prisma schema, migrations and generated Prisma Client for Triskcraft.

This package owns:

- `prisma/schema.prisma`
- `prisma/migrations`
- the generated Prisma Client exported by `@triskcraft/db`

Consumers should import the generated client from this package instead of keeping
their own Prisma schema copy.

```ts
import { PrismaClient, createPrismaClient } from '@triskcraft/db'
```

## Development

Requirements:

- Node.js 24 or newer
- pnpm 11
- a PostgreSQL database for local migrations

Install dependencies and verify the package:

```sh
pnpm install
pnpm run verify
```

Use `DATABASE_URL` for new services. `DATABASE_PATH` is still accepted as a
temporary compatibility fallback for the current bot configuration.

Useful commands:

| Command                                    | Purpose                                               |
| ------------------------------------------ | ----------------------------------------------------- |
| `pnpm run db:format`                       | Format `prisma/schema.prisma`.                        |
| `pnpm run db:validate`                     | Validate the Prisma schema.                           |
| `pnpm run db:migrate:dev -- --name <name>` | Create and apply a migration in development.          |
| `pnpm run db:migrate:status`               | Show migration status for the configured database.    |
| `pnpm run db:migrate:deploy`               | Apply pending migrations in a deployment environment. |
| `pnpm run prisma:generate`                 | Regenerate Prisma Client.                             |
| `pnpm run build`                           | Generate Prisma Client and compile the package.       |
| `pnpm run verify`                          | Build and check formatting.                           |

## Changing the schema

1. Create a branch for the change.
2. Update `prisma/schema.prisma`.
3. Create a migration against a development database:

   ```sh
   pnpm run db:migrate:dev -- --name descriptive_migration_name
   ```

4. Review the generated SQL in `prisma/migrations`. Confirm that it matches the
   intended change, preserves existing data and is safe for independently
   deployed consumers.
5. Run `pnpm run verify`.
6. Open a pull request containing the schema change and generated migration.
   Document compatibility considerations and any required data backfill or
   deployment ordering.

Never edit or replace a migration that may already have been applied outside a
local disposable database. Add a new corrective migration instead.

## Production migrations

The manual `Deploy database migrations` GitHub Actions workflow in this
repository is the only supported production migration runner. It uses the
protected `production` environment and serializes runs so two migration jobs
cannot execute concurrently.

To deploy pending migrations:

1. Open **Actions → Deploy database migrations → Run workflow**.
2. Select `main` and enter `migrate` in the confirmation input.
3. Approve the `production` environment deployment when required.
4. Review the schema validation and migration status output. The status step is
   informational because Prisma reports a non-zero exit code when migrations are
   pending; the workflow then applies them with:

```sh
pnpm run db:migrate:deploy
```

Configure the GitHub `production` environment with:

- a `DATABASE_URL` environment secret;
- required reviewers;
- deployment access restricted to the default branch.

Bot, API and other consumers must not run Prisma migrations during application
bootstrap, in their process entrypoints or as competing deployment steps. They
should fail normally if deployed against an incompatible schema instead of
modifying the database automatically.

Run the migration workflow in the deployment order documented by the pull
request. For destructive changes, prefer expand-and-contract migrations so
independently deployed bot and API versions can coexist temporarily:

1. add the new schema structure without removing the old structure;
2. publish and deploy consumers compatible with both versions;
3. backfill data when necessary;
4. stop consumers from using the old structure;
5. remove the old structure in a later migration.

## Using the package from a service

Install the canonical package:

```sh
pnpm add @triskcraft/db
```

Create one client instance for the service and disconnect it during graceful
shutdown:

```ts
import { createPrismaClient } from '@triskcraft/db'

export const prisma = createPrismaClient()
```

Consumers must not:

- keep a copy of `schema.prisma` or the migration history;
- generate a separate Prisma Client;
- create migrations outside this repository;
- run `prisma migrate deploy` during application startup.

## Versioning

This package follows Semantic Versioning:

- **Patch:** internal or documentation changes that do not change the generated
  client API.
- **Minor:** backward-compatible additions such as new models, optional fields,
  enums or exports.
- **Major:** removals, renames or other changes that break the generated client
  API for consumers.

Database compatibility and package API compatibility must both be reviewed. A
SQL migration can require coordinated deployment even when its generated client
change appears backward-compatible. Record user-visible changes and deployment
notes in `CHANGELOG.md`.

## Publishing

Package publication is performed by the `Publish package` workflow after changes
reach `main`:

1. Update `version` in `package.json` according to the versioning policy.
2. Add the release notes to `CHANGELOG.md`.
3. Open and merge a pull request containing those changes.
4. The workflow installs dependencies, runs `pnpm run verify`, checks whether the
   exact package version already exists and publishes a new version with npm
   provenance when needed.

Trusted Publishing provenance requires GitHub Actions OIDC. Local
`npm publish --provenance` is not the supported publication path and is expected
to fail with `provider: null`.

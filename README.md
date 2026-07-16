# @triskcraft/database

Canonical Prisma schema, migrations and generated Prisma Client for Triskcraft.

This package owns:

- `prisma/schema.prisma`
- `prisma/migrations`
- the generated Prisma Client exported by `@triskcraft/database`

Consumers should import the generated client from this package instead of keeping
their own Prisma schema copy.

```ts
import { PrismaClient, createPrismaClient } from '@triskcraft/database'
```

## Local setup

```sh
pnpm install
pnpm run build
```

Use `DATABASE_URL` for new services. `DATABASE_PATH` is still accepted as a
temporary compatibility fallback for the current bot configuration.

## Migrations

Migrations are not executed by service startup code. Production must have a
single deployment step that runs:

```sh
pnpm run db:migrate:deploy
```

Run that step before deploying services that depend on the new schema version.
For destructive changes, prefer progressive migrations so independently deployed
bot and API versions can coexist temporarily.

## Publishing

Publish from the GitHub Actions workflow on `main`. Trusted Publisher provenance
requires GitHub Actions OIDC, so local `npm publish --provenance` is expected to
fail with `provider: null`.

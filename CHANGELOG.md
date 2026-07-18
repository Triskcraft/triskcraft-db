# Changelog

All notable changes to `@triskcraft/db` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1]

### Added

- Development and migration maintenance documentation.
- A manual, protected production migration workflow.
- Prisma scripts for formatting, validation and migration management.
- A Prisma client factory in the package entry point for creating clients with PostgreSQL adapter support.
- Export @prisma/client runtime errors

### Changed

- Documented `@triskcraft/db` as the canonical package name.
- Updated the package entry point to initialize Prisma clients through `PrismaPg` using `DATABASE_URL` or `DATABASE_PATH`.

## [0.1.0]

### Added

- Canonical Prisma schema and migration history for Triskcraft services.
- Generated Prisma Client exports and `createPrismaClient` factory.
- Automated package publication with npm provenance.

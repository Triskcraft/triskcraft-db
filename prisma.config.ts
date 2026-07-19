import { defineConfig } from 'prisma/config'

try {
  process.loadEnvFile()
} catch {
  // Local development can provide DATABASE_URL through the shell or CI.
}

export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: process.env.DATABASE_URL ?? process.env.DATABASE_PATH!,
  },
  migrations: {
    seed: 'node ./src/seed.ts',
  },
})

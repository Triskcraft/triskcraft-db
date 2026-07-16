import { PrismaPg } from '@prisma/adapter-pg'
import { PrismaClient } from './generated/client.ts'

export * from './generated/client.ts'

export type CreatePrismaClientOptions = {
  connectionString?: string
}

export function createPrismaClient(options: CreatePrismaClientOptions = {}) {
  const connectionString =
    options.connectionString ??
    process.env.DATABASE_URL ??
    process.env.DATABASE_PATH

  if (!connectionString) {
    throw new Error(
      'DATABASE_URL or DATABASE_PATH is required to create a Prisma client.',
    )
  }

  return new PrismaClient({
    adapter: new PrismaPg({ connectionString }),
  })
}

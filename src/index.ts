import { PrismaPg } from '@prisma/adapter-pg'
import { PrismaClient } from './generated/client.ts'

export * from './generated/client.ts'

export {
  PrismaClientKnownRequestError,
  PrismaClientUnknownRequestError,
  PrismaClientInitializationError,
  PrismaClientRustPanicError,
  PrismaClientValidationError,
} from '@prisma/client/runtime/client'

export type CreatePrismaClientOptions = {
  connectionString?: string
}

export const STATE_KEYS = {
  SUPER_ROLE_ID: 'super_role_id',
  DEFAULT_ROLE_ID: 'default_role_id',
  DEFAULT_MINECRAFT_ROLE_ID: 'default_minecraft_role_id',
  WEBHOOK_PANEL_MESSAGE_ID: 'wh_panel_message_id',
  ROLES_PANEL_MESSAGE_ID: 'roles_panel_message_id',
  ROLES_PANEL_SELECTED_USER: 'roles_panel_selected_user',
  BLOG_PANEL_MESSAGE_ID: 'blog_panel_message_id',
} as const

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

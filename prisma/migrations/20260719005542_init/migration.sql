-- ! Migration customized for snowflake
-- ! This migration is not compatible with the default migration
-- ! You need to run this migration first

--Fecha base: 01 /06 / 2025
CREATE OR REPLACE FUNCTION snowflake(node_id int DEFAULT 0)
RETURNS text AS $$
DECLARE
    our_epoch bigint:= 1748736000000; --milisegundos desde 01 /06 / 2025
    seq_id bigint;
    now_millis bigint;
    safe_node_id int;
    snowflake_id bigint;
BEGIN
--Asegurar que node_id esté entre 0 y 1023(10 bits)
safe_node_id:= GREATEST(0, LEAST(node_id, 1023));

--Usar la secuencia para obtener un número siempre único
    SELECT nextval('snowflake_seq') % 4096 INTO seq_id; --12 bits
    SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;

snowflake_id:= ((now_millis - our_epoch) << 22)-- timestamp(41 bits)
    | ((safe_node_id & 1023) << 12)-- node id(10 bits)
        | (seq_id & 4095); --secuencia(12 bits)

    RETURN snowflake_id:: text; --Convertir a string
END;
$$ LANGUAGE plpgsql;

--Crear secuencia si no existe
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_class WHERE relname = 'snowflake_seq') THEN
        CREATE SEQUENCE snowflake_seq;
    END IF;
END$$;

-- ! Prisma generation

-- CreateEnum
CREATE TYPE "PLAYER_STATUS" AS ENUM ('ACTIVE', 'DELETED');

-- CreateEnum
CREATE TYPE "POST_STATUS" AS ENUM ('DRAFT', 'PUBLISHED', 'OUTDATED');

-- CreateEnum
CREATE TYPE "POST_BLOCK_MEDIA_TYPE" AS ENUM ('IMAGE', 'VIDEO', 'AUDIO', 'FILE');

-- CreateTable
CREATE TABLE "inactivity_periods" (
    "user_id" TEXT NOT NULL,
    "guild_id" TEXT NOT NULL,
    "role_snapshot" TEXT NOT NULL,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ends_at" TIMESTAMP(3) NOT NULL,
    "source" TEXT NOT NULL,
    "notified" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "inactivity_periods_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "tracked_roles" (
    "guild_id" TEXT NOT NULL,
    "role_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tracked_roles_pkey" PRIMARY KEY ("guild_id","role_id")
);

-- CreateTable
CREATE TABLE "role_statistics" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "guild_id" TEXT NOT NULL,
    "role_id" TEXT NOT NULL,
    "inactive_count" INTEGER NOT NULL DEFAULT 0,
    "active_count" INTEGER NOT NULL DEFAULT 0,
    "captured_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "role_statistics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "link_codes" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "discord_id" TEXT NOT NULL,
    "discord_nickname" TEXT NOT NULL,
    "code" TEXT NOT NULL,

    CONSTRAINT "link_codes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "minecraft_roles" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "name" TEXT NOT NULL,

    CONSTRAINT "minecraft_roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "linked_minecraft_roles" (
    "mc_user_uuid" TEXT NOT NULL,
    "role_id" TEXT NOT NULL,

    CONSTRAINT "linked_minecraft_roles_pkey" PRIMARY KEY ("mc_user_uuid","role_id")
);

-- CreateTable
CREATE TABLE "medias" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "mc_user_uuid" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "url" TEXT NOT NULL,

    CONSTRAINT "medias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "minecraft_players" (
    "uuid" TEXT NOT NULL,
    "nickname" TEXT NOT NULL,
    "digs" INTEGER NOT NULL DEFAULT 0,
    "description" TEXT NOT NULL DEFAULT '',
    "status" "PLAYER_STATUS" NOT NULL DEFAULT 'ACTIVE',
    "last_seen" TIMESTAMP(3),

    CONSTRAINT "minecraft_players_pkey" PRIMARY KEY ("uuid")
);

-- CreateTable
CREATE TABLE "discord_users" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,

    CONSTRAINT "discord_users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "webhook_tokens" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "name" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "secret" TEXT NOT NULL,
    "permissions" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "webhook_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "states" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "states_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "posts" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "title" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "thread_id" TEXT NOT NULL,
    "status" "POST_STATUS" NOT NULL DEFAULT 'DRAFT',
    "cover_media_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_blocks" (
    "message_id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "content" TEXT,
    "components" JSONB[] DEFAULT ARRAY[]::JSONB[],
    "embeds" JSONB[] DEFAULT ARRAY[]::JSONB[],
    "author_id" TEXT NOT NULL,

    CONSTRAINT "post_blocks_pkey" PRIMARY KEY ("message_id")
);

-- CreateTable
CREATE TABLE "post_media" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "filename" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "content_type" TEXT,
    "media_type" "POST_BLOCK_MEDIA_TYPE" NOT NULL,
    "size" INTEGER NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "description" TEXT,
    "hash" TEXT,

    CONSTRAINT "post_media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_block_media" (
    "post_block_message_id" TEXT NOT NULL,
    "media_id" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "post_block_media_pkey" PRIMARY KEY ("post_block_message_id","media_id","position")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "mc_player_uuid" TEXT,
    "discord_user_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clients" (
    "id" TEXT NOT NULL,
    "client_secret" TEXT,
    "redirect_uris" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "scopes" TEXT[],

    CONSTRAINT "clients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "authorization_codes" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "code" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "redirect_uri" TEXT NOT NULL,
    "code_challenge" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scope" TEXT NOT NULL,

    CONSTRAINT "authorization_codes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "user_id" TEXT NOT NULL,
    "refresh_token" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "scope" TEXT NOT NULL DEFAULT '',
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" TEXT NOT NULL DEFAULT snowflake(),
    "name" TEXT NOT NULL,
    "permissions" BIGINT NOT NULL DEFAULT 0,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "linked_roles" (
    "user_id" TEXT NOT NULL,
    "role_id" TEXT NOT NULL,

    CONSTRAINT "linked_roles_pkey" PRIMARY KEY ("user_id","role_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "link_codes_discord_id_key" ON "link_codes"("discord_id");

-- CreateIndex
CREATE UNIQUE INDEX "link_codes_code_key" ON "link_codes"("code");

-- CreateIndex
CREATE UNIQUE INDEX "minecraft_roles_name_key" ON "minecraft_roles"("name");

-- CreateIndex
CREATE UNIQUE INDEX "medias_mc_user_uuid_type_key" ON "medias"("mc_user_uuid", "type");

-- CreateIndex
CREATE UNIQUE INDEX "minecraft_players_nickname_key" ON "minecraft_players"("nickname");

-- CreateIndex
CREATE UNIQUE INDEX "discord_users_username_key" ON "discord_users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "webhook_tokens_name_key" ON "webhook_tokens"("name");

-- CreateIndex
CREATE UNIQUE INDEX "states_key_key" ON "states"("key");

-- CreateIndex
CREATE UNIQUE INDEX "posts_title_key" ON "posts"("title");

-- CreateIndex
CREATE UNIQUE INDEX "posts_cover_media_id_key" ON "posts"("cover_media_id");

-- CreateIndex
CREATE INDEX "post_media_hash_idx" ON "post_media"("hash");

-- CreateIndex
CREATE INDEX "post_media_media_type_idx" ON "post_media"("media_type");

-- CreateIndex
CREATE INDEX "post_block_media_media_id_idx" ON "post_block_media"("media_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_mc_player_uuid_key" ON "users"("mc_player_uuid");

-- CreateIndex
CREATE UNIQUE INDEX "users_discord_user_id_key" ON "users"("discord_user_id");

-- CreateIndex
CREATE UNIQUE INDEX "authorization_codes_code_key" ON "authorization_codes"("code");

-- CreateIndex
CREATE UNIQUE INDEX "sessions_refresh_token_key" ON "sessions"("refresh_token");

-- CreateIndex
CREATE UNIQUE INDEX "roles_name_key" ON "roles"("name");

-- AddForeignKey
ALTER TABLE "inactivity_periods" ADD CONSTRAINT "inactivity_periods_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "discord_users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "link_codes" ADD CONSTRAINT "link_codes_discord_id_fkey" FOREIGN KEY ("discord_id") REFERENCES "discord_users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "linked_minecraft_roles" ADD CONSTRAINT "linked_minecraft_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "minecraft_roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "linked_minecraft_roles" ADD CONSTRAINT "linked_minecraft_roles_mc_user_uuid_fkey" FOREIGN KEY ("mc_user_uuid") REFERENCES "minecraft_players"("uuid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medias" ADD CONSTRAINT "medias_mc_user_uuid_fkey" FOREIGN KEY ("mc_user_uuid") REFERENCES "minecraft_players"("uuid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "webhook_tokens" ADD CONSTRAINT "webhook_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_cover_media_id_fkey" FOREIGN KEY ("cover_media_id") REFERENCES "post_media"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_blocks" ADD CONSTRAINT "post_blocks_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "discord_users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_blocks" ADD CONSTRAINT "post_blocks_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_block_media" ADD CONSTRAINT "post_block_media_post_block_message_id_fkey" FOREIGN KEY ("post_block_message_id") REFERENCES "post_blocks"("message_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_block_media" ADD CONSTRAINT "post_block_media_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "post_media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_mc_player_uuid_fkey" FOREIGN KEY ("mc_player_uuid") REFERENCES "minecraft_players"("uuid") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_discord_user_id_fkey" FOREIGN KEY ("discord_user_id") REFERENCES "discord_users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "authorization_codes" ADD CONSTRAINT "authorization_codes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "authorization_codes" ADD CONSTRAINT "authorization_codes_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "linked_roles" ADD CONSTRAINT "linked_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "linked_roles" ADD CONSTRAINT "linked_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

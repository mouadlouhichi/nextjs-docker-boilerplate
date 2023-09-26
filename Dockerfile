# Install dependencies only when needed
FROM node:18-alpine AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk update && apk add --no-cache libc6-compat && apk add git
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --immutable


# Rebuild the source code only when needed
FROM node:alpine AS builder
# add environment variables to client code

# add environment variables to client code
ARG DATABASE_URL_ARG="postgresql://postgres:test@db.test.supabase.co:5432/postgres"
ARG NEXTAUTH_SECRET_ARG="secret"
ARG NEXTAUTH_URL_ARG="https://mindrested-app.vercel.app"
ARG ANALYZE_ARG="false"
ARG NEXT_PUBLIC_APP_URL_ARG="https://mindrested-app.vercel.app"
ARG NEXT_PUBLIC_VERCEL_URL_ARG="secret"
ARG LOGLIB_API_KEY_ARG="secret"
ARG LOGLIB_SITE_ID_ARG="secret"
ARG LINKEDIN_ID_ARG="secret"
ARG LINKEDIN_SECRET_ARG="secret"
ARG FACEBOOK_ID_ARG="secret"
ARG FACEBOOK_SECRET_ARG="secret"

ENV DATABASE_URL=$DATABASE_URL_ARG
ENV NEXTAUTH_SECRET=$NEXTAUTH_SECRET_ARG
ENV NEXTAUTH_URL=$NEXTAUTH_URL_ARG
ENV ANALYZE=$ANALYZE_ARG
ENV NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL_ARG
ENV NEXT_PUBLIC_VERCEL_URL=$NEXT_PUBLIC_VERCEL_URL_ARG
ENV LOGLIB_API_KEY=$LOGLIB_API_KEY_ARG
ENV LOGLIB_SITE_ID=$LOGLIB_SITE_ID_ARG
ENV LINKEDIN_ID=$LINKEDIN_ID_ARG
ENV LINKEDIN_SECRET=$LINKEDIN_SECRET_ARG
ENV FACEBOOK_ID=$FACEBOOK_ID_ARG
ENV FACEBOOK_SECRET=$FACEBOOK_SECRET_ARG

WORKDIR /app
COPY . .
COPY --from=deps /app/node_modules ./node_modules
ARG NODE_ENV=production
RUN echo ${NODE_ENV}
RUN NODE_ENV=${NODE_ENV} yarn build

# Production image, copy all the files and run next
FROM node:alpine AS runner
WORKDIR /app
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# You only need to copy next.config.js if you are NOT using the default configuration. 
# Copy all necessary files used by nex.config as well otherwise the build will fail

COPY --from=builder /app/next.config.js ./next.config.js
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pages ./pages

USER nextjs

# Expose
EXPOSE 3000

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry.
ENV NEXT_TELEMETRY_DISABLED 1
CMD ["yarn", "start"]


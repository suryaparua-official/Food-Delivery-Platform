# ---- build stage ----
FROM node:22-alpine AS builder

WORKDIR /app

# install deps
COPY package*.json ./
RUN npm ci

# copy all files
COPY . .

# build next app
RUN npm run build


# ---- production stage ----
FROM node:22-alpine

WORKDIR /app

# set env
ENV NODE_ENV=production

# install only production deps
COPY package*.json ./
RUN npm ci --omit=dev

# copy build output
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.ts ./next.config.ts
COPY --from=builder /app/package.json ./package.json

# expose port
EXPOSE 3000

# start app
CMD ["npm", "start"]
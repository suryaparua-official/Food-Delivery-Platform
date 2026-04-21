# ---- build stage ----
FROM node:22-alpine AS builder

WORKDIR /app

# install deps
COPY package*.json ./
RUN npm ci

# copy all files
COPY . .

# build vite app
RUN npm run build


# ---- production stage ----
FROM node:22-alpine

WORKDIR /app

ENV NODE_ENV=production

# install serve (to serve static files)
RUN npm install -g serve

# copy build output (IMPORTANT CHANGE)
COPY --from=builder /app/dist ./dist

# expose port
EXPOSE 3000

# start app
CMD ["serve", "-s", "dist", "-l", "3000"]
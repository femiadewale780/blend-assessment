# Use Node.js 18 LTS (Long Term Support) version
FROM node:18-bookworm-slim AS deps

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies for caching
RUN npm ci

# ---- build (Debian/glibc) ----
FROM node:18-bookworm-slim AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build Next.js (SWC works on glibc here)
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Create non-root user/group
RUN addgroup -S app && adduser -S app -G app

# Copy minimal runtime artifacts
COPY --from=builder /app/.next/static ./.next/static

# Standalone includes the server + required node_modules subset
COPY --from=builder /app/.next/standalone ./

# Ensure permissions
RUN chown -R app:app /app

USER app

EXPOSE 3000

# In standalone mode, server.js is at the root of the standalone copy
CMD ["node", "server.js"]
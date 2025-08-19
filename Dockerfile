# Multi-stage Dockerfile for BookEase - builds both frontend and backend
ARG TARGET=frontend

# ==================== BACKEND BUILD ====================
FROM node:18-alpine AS backend-build
WORKDIR /app
COPY demo-strapi/package*.json ./
RUN npm config set registry https://registry.npmjs.org/ \
    && npm config set fetch-retry-maxtimeout 600000 \
    && npm config set fetch-timeout 600000 \
    && npm install --production --silent
COPY demo-strapi/ ./
RUN npm run build

# ==================== FRONTEND BUILD ====================
FROM node:18-alpine AS frontend-build
WORKDIR /app
COPY demo-project/package*.json ./
RUN npm config set registry https://registry.npmjs.org/ \
    && npm config set fetch-retry-maxtimeout 600000 \
    && npm config set fetch-timeout 600000 \
    && npm install --silent
COPY demo-project/ ./
RUN npm run build

# ==================== BACKEND PRODUCTION ====================
FROM node:18-alpine AS backend-prod
WORKDIR /app
ENV NODE_ENV=production
COPY --from=backend-build /app/ ./
EXPOSE 1337
CMD ["npm", "start"]

# ==================== FRONTEND PRODUCTION ====================
FROM node:18-alpine AS frontend-prod
WORKDIR /app
ENV NODE_ENV=production
COPY --from=frontend-build /app/package*.json ./
COPY --from=frontend-build /app/.next ./.next
COPY --from=frontend-build /app/public ./public
COPY --from=frontend-build /app/node_modules ./node_modules
EXPOSE 3000
CMD ["npm", "start"]

# ==================== FINAL TARGET SELECTOR ====================
FROM ${TARGET}-prod AS final
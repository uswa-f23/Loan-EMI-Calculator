FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
COPY node_modules ./node_modules
COPY server.js ./
COPY public ./public

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

ENV PORT=3000
EXPOSE 3000

CMD ["node", "server.js"]

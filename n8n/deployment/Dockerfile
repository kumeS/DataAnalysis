# n8n × Claude Code Automation Platform
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production

# Copy application code
COPY cli/ ./cli/
COPY workflows/ ./workflows/

# Create logs and data directories
RUN mkdir -p logs data

# Create non-root user
RUN addgroup -g 1001 -S n8nuser && \
    adduser -S n8nuser -u 1001
RUN chown -R n8nuser:n8nuser /app
USER n8nuser

# Expose port
EXPOSE 3000

# Environment variables
ENV NODE_ENV=production
ENV LOG_LEVEL=info
ENV N8N_PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e "const http = require('http'); \
    const req = http.request('http://localhost:3000/health', res => process.exit(res.statusCode === 200 ? 0 : 1)); \
    req.on('error', () => process.exit(1)); \
    req.end();"

# Start command
CMD ["npm", "start"]
# =============================================================================
# OpenCode - Build from source
# Multi-stage: Bun build → Alpine runtime
# =============================================================================

# Stage 1: Build
FROM oven/bun:1 AS builder

WORKDIR /build
COPY . .

# Install dependencies
RUN bun install --frozen-lockfile || bun install

# Build the OpenCode binary for linux-x64
RUN cd packages/opencode && bun run script/build.ts

# Find and stage the correct binary
RUN BINARY=$(find /build -name "opencode-linux-x64*musl*" -type f | head -1) && \
    if [ -z "$BINARY" ]; then \
      BINARY=$(find /build -name "opencode-linux-x64*" -type f | head -1); \
    fi && \
    if [ -z "$BINARY" ]; then \
      echo "ERROR: No linux-x64 binary found!" && exit 1; \
    fi && \
    echo "Found binary: $BINARY" && \
    cp "$BINARY" /build/opencode-binary && \
    chmod +x /build/opencode-binary

# Stage 2: Runtime
FROM alpine:3.20

RUN apk add --no-cache \
    git \
    bash \
    curl \
    openssh-client \
    ca-certificates

COPY --from=builder /build/opencode-binary /usr/local/bin/opencode

WORKDIR /workspace

ENTRYPOINT ["opencode"]

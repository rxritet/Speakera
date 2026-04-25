# ─── Build Stage ──────────────────────────────────────────────────────────────
FROM dart:stable AS builder

WORKDIR /build

# Cache pub dependencies separately from source code
COPY server/pubspec.yaml server/pubspec.lock* server/
RUN cd server && dart pub get --no-precompile

# Copy server source and SQL migrations
COPY server/     server/

# Compile both binaries to self-contained native executables
RUN mkdir -p /build/out \
    && dart compile exe server/bin/server.dart  -o /build/out/server \
    && dart compile exe server/bin/migrate.dart -o /build/out/migrate

# ─── Runtime Stage ────────────────────────────────────────────────────────────
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /build/out/server    /app/bin/server
COPY --from=builder /build/out/migrate   /app/bin/migrate
COPY --from=builder /build/server/migrations    /app/migrations

# The dotenv package calls load(['.env']) / load(['../.env']).
# With includePlatformEnvironment: true the real config is read from
# Docker env vars; these empty files just prevent a "file not found" error.
RUN touch /app/.env \
    && mkdir -p /app/server \
    && touch /app/server/.env

EXPOSE 8080

CMD ["/app/bin/server"]

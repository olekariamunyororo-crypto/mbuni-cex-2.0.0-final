# Mbuni CEX 2.0 — Go services Dockerfile (used for all 4 Go services)
# Build context = repo root.  Requires go.sum committed (run `go mod tidy` in each service).
FROM golang:1.23-alpine AS builder
ARG SERVICE_NAME
WORKDIR /app
COPY proto/ /app/proto/
COPY services/${SERVICE_NAME}/ /app/services/${SERVICE_NAME}/
WORKDIR /app/services/${SERVICE_NAME}
RUN go mod download
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /app/server ./cmd/

# --- Runtime: ~2 MB static base, non-root (was golang:1.23-slim, ~700 MB, root) ---
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]

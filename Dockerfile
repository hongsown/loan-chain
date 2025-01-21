# Build stage
FROM golang:1.22-alpine3.19 AS builder

# Set working directory
WORKDIR /app

# Install necessary build tools
RUN apk add --no-cache make git gcc musl-dev

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o build/loand ./cmd/loand

# Final stage
FROM alpine:3.19

WORKDIR /root

# Install necessary runtime dependencies
RUN apk add --no-cache ca-certificates jq curl bash

# Copy the binary and start script
COPY --from=builder /app/build/loand /usr/local/bin/
COPY start.sh /root/

# Make start script executable
RUN chmod +x /root/start.sh

# Create directory for chain data
RUN mkdir -p /root/.loan

# Expose necessary ports
EXPOSE 26656 26657 1317 9090

# Set environment variables
ENV MONIKER="loan-validator" \
    CHAIN_ID="loan-1" \
    MINIMUM_GAS_PRICES="0stake"

# Use start script as entrypoint
ENTRYPOINT ["/root/start.sh"] 
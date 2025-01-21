# Build stage
FROM golang:1.22-alpine AS builder

# Set working directory
WORKDIR /app

# Install necessary build tools
RUN apk add --no-cache make git

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the application
RUN make build

# Final stage
FROM alpine:latest

WORKDIR /root

# Install necessary runtime dependencies
RUN apk add --no-cache bash curl jq

# Copy the binary and start script
COPY --from=builder /app/build/loand /usr/local/bin/
COPY start.sh /root/

# Make start script executable
RUN chmod +x /root/start.sh

# Create directory for chain data
RUN mkdir -p /root/.loan

# Expose necessary ports (adjust as needed)
EXPOSE 26656 26657 1317 9090

# Use start script as entrypoint
ENTRYPOINT ["/root/start.sh"] 
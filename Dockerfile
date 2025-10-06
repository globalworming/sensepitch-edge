FROM openjdk:21-jdk-slim

# Install openssl for certificate generation
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# Create directories for SSL certificates and logs
RUN mkdir -p /app/ssl /app/logs

# Copy the JAR file from the target directory
COPY ../target/sensepitch-edge-1.0-SNAPSHOT-with-dependencies.jar /app/sensepitch-edge.jar

RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /app/ssl/nginx.key \
    -out /app/ssl/nginx.crt \
    -subj "/CN=localhost"

# Set working directory
WORKDIR /app

# Required environment variables for sensepitch-edge configuration:
#
# Note: SENSEPITCH_EDGE_SITES_0_UPSTREAM_TARGET must be provided when running the container
# as it depends on the target service (e.g., "nginx-static:80")
ENV SENSEPITCH_EDGE_LISTEN_HTTPS_PORT=17443 \
    SENSEPITCH_EDGE_LISTEN_SSL_KEY_PATH=/app/ssl/nginx.key \
    SENSEPITCH_EDGE_LISTEN_SSL_CERT_PATH=/app/ssl/nginx.crt \
    SENSEPITCH_EDGE_PROTECTION_DISABLE=true \
    SENSEPITCH_EDGE_SITES_0_KEY=localhost \
    SENSEPITCH_EDGE_METRICS_ENABLE=true

# Expose the HTTPS port
EXPOSE 17443

# Run the Java application with the same options as start.sh
# The UPSTREAM_TARGET will need to be set when running the container
CMD java -XX:+UseZGC --enable-native-access=ALL-UNNAMED \
    -jar /app/sensepitch-edge.jar > /app/logs/sensepitch-edge.log 2>&1

# Purpose: Build the Campus Notice Board application using a small Python Alpine image.
# Build command: docker build -t notice-board:02230153-1.0.0 --build-arg APP_VERSION=1.0.0 .\app

FROM python:3.13-alpine

# Set the application version when building each release image.
ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION}

# Identify the student in every /version response.
ENV STUDENT_ID=02230153

# Keep pinned notices disabled by default; enable them at runtime for the later release.
ENV FEATURE_PINNED=false

# Make the broken release configurable at build time; normal releases keep health checks enabled.
ARG BROKEN_HEALTH=false
ENV BROKEN_HEALTH=${BROKEN_HEALTH}

# Create a dedicated unprivileged user to avoid running the application as root.
RUN adduser -D -u 10001 appuser

# Use a dedicated directory for the application.
WORKDIR /app

# Copy the application source into the image.
COPY server.py /app/server.py

# Document the port used by the HTTP server.
EXPOSE 8080

# Run the application as the unprivileged user.
USER 10001

# Start the application.
CMD ["python3", "/app/server.py"]
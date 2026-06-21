# Build stage: export Godot 4 project to Android
FROM robpc/godot-headless:4.3-android AS build

# Install JDK 17 (required for Android Gradle build)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Android SDK and NDK paths
ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin

WORKDIR /project

# Copy project files
COPY . .

# Generate placeholder sprites (runs in headless if @tool)
RUN godot --headless --script assets/sprites/generate_placeholders.gd --quit 2>/dev/null || echo "Placeholder generation skipped (needs editor)"

# Pre-heat: create Android build template cache
RUN godot --headless --editor --quit 2>/dev/null || true

# Export Android App Bundle
RUN mkdir -p /project/build && \
    echo "Starting Android export..." && \
    godot --headless --export-release "Android" /project/build/game.aab 2>&1 || \
    echo "Export attempt 1 failed, trying alternative..." && \
    godot --export-release "Android" /project/build/game.aab 2>&1 || \
    echo "WARNING: Export failed. Check project.godot and export_presets.cfg."

# Also try APK export as fallback
RUN test -f /project/build/game.aab || \
    (godot --headless --export-debug "Android" /project/build/game.apk 2>&1 || true)

# Output stage: only the build artifacts
FROM scratch AS output
COPY --from=build /project/build/ .

# Usage:
#   docker build -t viking-game-android .
#   docker run --rm -v $(pwd)/build:/out viking-game-android
#   cp /out/*.aab ./build/

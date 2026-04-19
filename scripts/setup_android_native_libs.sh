#!/bin/bash
# =============================================================================
# RunAnywhere Android Native Libraries Fix
# =============================================================================
# The RunAnywhere Flutter plugin v0.16.0 has broken Android download URLs.
# The native .so binaries were NEVER published to GitHub releases.
#
# This script patches the pub cache plugin build.gradle files to gracefully
# handle the missing downloads so the Android build doesn't crash.
#
# The app will build and run on Android, but runanywhere native AI features
# (LLM, STT, TTS, VAD) won't function until the plugin authors publish
# Android native binaries. All other app features will work normally.
#
# Usage:
#   macOS/Linux: bash scripts/setup_android_native_libs.sh
#   Windows:     Run the equivalent sed commands manually (see below)
# =============================================================================

set -e

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " RunAnywhere Android Build Fix"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Detect pub cache directory
if [ -n "$PUB_CACHE" ]; then
    PUB_CACHE_DIR="$PUB_CACHE"
elif [ -d "$HOME/.pub-cache" ]; then
    PUB_CACHE_DIR="$HOME/.pub-cache"
else
    echo "❌ Could not find pub cache directory"
    echo "   Set PUB_CACHE environment variable and try again."
    exit 1
fi

HOSTED_DIR="$PUB_CACHE_DIR/hosted/pub.dev"

# Find all runanywhere plugin versions
PLUGINS=()
for dir in "$HOSTED_DIR"/runanywhere-*/android "$HOSTED_DIR"/runanywhere_llamacpp-*/android "$HOSTED_DIR"/runanywhere_onnx-*/android; do
    if [ -d "$dir" ]; then
        PLUGINS+=("$dir")
    fi
done

if [ ${#PLUGINS[@]} -eq 0 ]; then
    echo "❌ No runanywhere plugins found in pub cache."
    echo "   Run 'flutter pub get' first."
    exit 1
fi

PATCHED=0
for PLUGIN_DIR in "${PLUGINS[@]}"; do
    BUILD_FILE="$PLUGIN_DIR/build.gradle"
    PLUGIN_NAME=$(basename "$(dirname "$PLUGIN_DIR")")

    if [ ! -f "$BUILD_FILE" ]; then
        continue
    fi

    # Check if already patched
    if grep -q "Download failed (Android binaries not yet published)" "$BUILD_FILE" 2>/dev/null; then
        echo "  ✓ Already patched: $PLUGIN_NAME"
        continue
    fi

    # Check if it has the download task with ant.get
    if grep -q "ant.get(src: downloadUrl, dest: zipFile)" "$BUILD_FILE" 2>/dev/null; then
        # Wrap ant.get in try-catch so build doesn't fail
        sed -i.bak 's|ant.get(src: downloadUrl, dest: zipFile)|try { ant.get(src: downloadUrl, dest: zipFile) } catch (Exception e) { println "⚠️  Download failed (Android binaries not yet published): ${e.message}"; println "   The app will build but runanywhere native features may not work on Android."; return }|' "$BUILD_FILE"
        rm -f "${BUILD_FILE}.bak"
        echo "  ✓ Patched: $PLUGIN_NAME"
        PATCHED=$((PATCHED + 1))
    else
        echo "  - Skipped (no ant.get found): $PLUGIN_NAME"
    fi
done

echo ""
if [ $PATCHED -gt 0 ]; then
    echo "✅ Patched $PATCHED plugin(s). Android build will now succeed."
else
    echo "✅ All plugins already patched."
fi
echo ""
echo "NOTE: The runanywhere AI features (LLM, STT, TTS, VAD) require"
echo "Android native binaries (.so files) that haven't been published"
echo "by the plugin authors yet. The app will build and run, but these"
echo "specific features won't work on Android until the authors fix this."
echo ""
echo "All other app features will work normally on Android."
echo ""
echo "If you run 'flutter pub get' with --offline or clear the cache,"
echo "re-run this script to re-apply the patch."
echo ""

#!/bin/bash

# Quick build status checker
echo "🔍 Checking OpenPano Android build status..."

if [ -f "app/build/outputs/aar/app-release.aar" ]; then
    echo "✅ Release AAR found!"
    ls -la app/build/outputs/aar/app-release.aar
    echo ""
    echo "📦 AAR details:"
    unzip -l app/build/outputs/aar/app-release.aar | head -20
else
    echo "❌ Release AAR not found."
    echo ""
    echo "📁 Checking build directory:"
    if [ -d "app/build" ]; then
        echo "Build directory exists"
        find app/build -name "*.aar" -o -name "*.so" | head -10
    else
        echo "No build directory found"
    fi
fi

echo ""
echo "🔨 To build:"
echo "./gradlew assembleRelease"

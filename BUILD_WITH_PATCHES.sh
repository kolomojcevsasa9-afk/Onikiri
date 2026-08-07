#!/bin/bash

# ==========================================
# Leaves Patches Build Script for Onikiri
# ==========================================
# This script applies all Leaves patches and builds the project with conflict detection
# Usage: ./BUILD_WITH_PATCHES.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATCHES_DIR="$SCRIPT_DIR/patches"
BUILD_LOG="$SCRIPT_DIR/build.log"
CONFLICTS_LOG="$SCRIPT_DIR/CONFLICTS_REPORT.log"
CONFLICT_FILES="$SCRIPT_DIR/CONFLICT_FILES.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Leaves Patches Build Script - Onikiri 1.21.1${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Clear previous logs
> "$BUILD_LOG"
> "$CONFLICTS_LOG"
> "$CONFLICT_FILES"

# ==========================================
# STEP 1: Check Prerequisites
# ==========================================
echo -e "${BLUE}[STEP 1]${NC} Checking prerequisites..."
echo "[BUILD LOG] Checking prerequisites..." >> "$BUILD_LOG"

if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git not found!${NC}"
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java not found!${NC}"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | grep -oP 'version "\K[^"]+')
echo -e "${GREEN}✓ Git: $(git --version)${NC}"
echo -e "${GREEN}✓ Java: $JAVA_VERSION${NC}"
echo "[BUILD LOG] Prerequisites OK" >> "$BUILD_LOG"
echo ""

# ==========================================
# STEP 2: Apply Patches with Conflict Detection
# ==========================================
echo -e "${BLUE}[STEP 2]${NC} Applying patches..."
echo "[BUILD LOG] Starting patch application..." >> "$BUILD_LOG"

APPLIED=0
CONFLICTS=0
FAILED=0
CONFLICT_PATCH_LIST=""

for patch_file in "$PATCHES_DIR"/*.patch; do
    if [ ! -f "$patch_file" ]; then
        continue
    fi
    
    patch_name=$(basename "$patch_file")
    echo -n "  $patch_name... "
    echo "[BUILD LOG] Processing: $patch_name" >> "$BUILD_LOG"
    
    # Check if patch can be applied cleanly
    if git apply --check "$patch_file" 2>&1 | tee -a "$BUILD_LOG" > /dev/null; then
        # No conflicts, apply normally
        if git apply "$patch_file" 2>&1 | tee -a "$BUILD_LOG"; then
            echo -e "${GREEN}✓ APPLIED${NC}"
            ((APPLIED++))
        else
            echo -e "${RED}✗ APPLY ERROR${NC}"
            echo "$patch_name - Apply Error" >> "$CONFLICTS_LOG"
            ((FAILED++))
        fi
    else
        # Conflicts detected, apply with --reject
        echo -e "${YELLOW}⚠ CONFLICT${NC}"
        git apply "$patch_file" --reject 2>&1 | tee -a "$BUILD_LOG" || true
        ((CONFLICTS++))
        CONFLICT_PATCH_LIST="$CONFLICT_PATCH_LIST\n  - $patch_name"
        
        # Log the conflict
        echo "" >> "$CONFLICTS_LOG"
        echo "=== PATCH: $patch_name ===" >> "$CONFLICTS_LOG"
        echo "Status: CONFLICT DETECTED" >> "$CONFLICTS_LOG"
        
        # Find .rej files
        echo "Conflicting sections:" >> "$CONFLICTS_LOG"
        find . -name "*.rej" -type f 2>/dev/null | while read rej_file; do
            echo "  - $rej_file" >> "$CONFLICTS_LOG"
            echo "$rej_file" >> "$CONFLICT_FILES"
        done
    fi
done

echo ""
echo -e "${BLUE}[PATCH SUMMARY]${NC}"
echo "  Applied: $APPLIED"
echo "  Conflicts: $CONFLICTS"
echo "  Failed: $FAILED"
echo ""

# ==========================================
# STEP 3: Handle Conflicts
# ==========================================
if [ $CONFLICTS -gt 0 ] || [ $FAILED -gt 0 ]; then
    echo -e "${YELLOW}⚠ WARNING: Conflicts detected!${NC}"
    echo ""
    echo "Patches with conflicts:"
    echo -e "$CONFLICT_PATCH_LIST"
    echo ""
    echo "Conflicting files (.rej):"
    cat "$CONFLICT_FILES"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review .rej files in your editor"
    echo "2. Manually merge conflicts into source files"
    echo "3. Delete .rej files when resolved"
    echo "4. Run: git add . && git commit -m 'Resolve patch conflicts'"
    echo "5. Re-run this script: ./BUILD_WITH_PATCHES.sh"
    echo ""
    echo -e "${YELLOW}Conflict details saved to: $CONFLICTS_LOG${NC}"
    exit 1
else
    echo -e "${GREEN}✓ All patches applied successfully! No conflicts detected.${NC}"
    echo ""
fi

# ==========================================
# STEP 4: Setup Gradle Build
# ==========================================
echo -e "${BLUE}[STEP 3]${NC} Setting up Gradle build..."
echo "[BUILD LOG] Starting Gradle build..." >> "$BUILD_LOG"

if [ ! -f "gradlew" ]; then
    echo -e "${RED}✗ gradlew not found in repository root!${NC}"
    echo "[BUILD LOG] ERROR: gradlew not found" >> "$BUILD_LOG"
    exit 1
fi

chmod +x gradlew
echo -e "${GREEN}✓ Gradle wrapper ready${NC}"
echo ""

# ==========================================
# STEP 5: Apply Patches via Gradle
# ==========================================
echo -e "${BLUE}[STEP 4]${NC} Running Gradle applyPatches..."
echo ""

if ./gradlew applyPatches 2>&1 | tee -a "$BUILD_LOG"; then
    echo -e "${GREEN}✓ Patches applied via Gradle${NC}"
else
    echo -e "${RED}✗ Gradle applyPatches failed!${NC}"
    echo "[BUILD LOG] ERROR: Gradle applyPatches failed" >> "$BUILD_LOG"
    echo ""
    echo "Check build.log for details"
    exit 1
fi

echo ""

# ==========================================
# STEP 6: Build Project
# ==========================================
echo -e "${BLUE}[STEP 5]${NC} Building Onikiri with Leaves patches..."
echo ""

if ./gradlew build --no-daemon 2>&1 | tee -a "$BUILD_LOG"; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    BUILD_SUCCESS=1
else
    echo -e "${RED}✗ Build failed!${NC}"
    echo "[BUILD LOG] ERROR: Build failed" >> "$BUILD_LOG"
    BUILD_SUCCESS=0
fi

echo ""

# ==========================================
# STEP 7: Locate Build Artifacts
# ==========================================
echo -e "${BLUE}[STEP 6]${NC} Locating build artifacts..."
echo ""

if [ $BUILD_SUCCESS -eq 1 ]; then
    # Find server JAR
    SERVER_JAR=$(find build/libs -name "*.jar" -type f 2>/dev/null | head -1)
    
    if [ -n "$SERVER_JAR" ]; then
        JAR_SIZE=$(du -h "$SERVER_JAR" | cut -f1)
        echo -e "${GREEN}✓ Server JAR built:${NC}"
        echo "  Path: $SERVER_JAR"
        echo "  Size: $JAR_SIZE"
        echo ""
    else
        echo -e "${YELLOW}⚠ Server JAR not found in build/libs${NC}"
    fi
fi

# ==========================================
# FINAL SUMMARY
# ==========================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Build Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Patches Applied: $APPLIED"
echo "Conflicts: $CONFLICTS"
echo "Failed: $FAILED"
echo "Build Status: $([ $BUILD_SUCCESS -eq 1 ] && echo -e "${GREEN}SUCCESS${NC}" || echo -e "${RED}FAILED${NC}")"
echo ""
echo "Build log: $BUILD_LOG"
echo "Conflict log: $CONFLICTS_LOG"
echo ""

if [ $BUILD_SUCCESS -eq 1 ]; then
    echo -e "${GREEN}✓ Build completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}✗ Build failed. Check logs for details.${NC}"
    exit 1
fi

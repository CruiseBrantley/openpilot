#!/bin/bash
set -e

# Configuration
BRANCH="ioniq-5-firestar"
PREBUILT_BRANCH="${BRANCH}-prebuilt"

echo "Starting Openpilot Build Process..."
cd "$(dirname "$0")"

# Configure identity
git config user.email "cruise.brantley@gmail.com"
git config user.name "Cruise Brantley"

# --- 0. Setup Environment ---
echo "[0/3] Setting up Environment..."
./tools/install_python_dependencies.sh
source .venv/bin/activate

# Check scons in venv
if ! command -v scons &> /dev/null; then
    echo "scons not found in venv. Installing..."
    pip install scons
fi

# --- 1. Update Source ---
echo "[1/3] Syncing with Remote..."
git fetch origin
git submodule update --init --recursive

# --- 2. Compile ---
echo "[2/3] Compiling (Native ARM64)..."
scons -c
scons -j$(sysctl -n hw.ncpu)

# --- 3. Package and Push ---
echo "[3/3] Creating and Pushing Prebuilts..."
git checkout -B $PREBUILT_BRANCH

# Force add binaries
find . -name '*.so' -type f -exec git add -f {} +
find . -name 'panda.bin.signed' -type f -exec git add -f {} +

git add .
git commit -m "Update prebuilts (native): $(date)" || echo "Nothing to commit"

echo "Pushing to origin/$PREBUILT_BRANCH..."
GIT_LFS_SKIP_PUSH=1 git push -f origin $PREBUILT_BRANCH

# Switch back
git checkout $BRANCH

echo "Done! Prebuilts available at branch: $PREBUILT_BRANCH"

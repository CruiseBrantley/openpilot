#!/bin/bash
set -e

PREBUILT_BRANCH="ioniq-5-firestar-prebuilt"

# Set git identity for CI
if [ -z "$(git config user.email)" ]; then
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git config user.name "github-actions[bot]"
fi

# Ensure commaai remote exists
if ! git remote | grep -q "^commaai$"; then
    git remote add commaai https://github.com/commaai/openpilot.git
fi

# 1. Fetch and checkout nightly
echo "[1/4] Fetching upstream nightly..."
git fetch commaai nightly --no-tags
echo "[2/4] Resetting $PREBUILT_BRANCH to nightly..."
git checkout -f -B $PREBUILT_BRANCH commaai/nightly

# 2. Apply Ioniq 5 tuning patches
echo "[3/4] Applying Ioniq 5 tuning..."
sed -i 's/^KP = 0.8$/KP = 0.5/'    selfdrive/controls/lib/latcontrol_torque.py
sed -i 's/^KI = 0.15$/KI = 0.25/'  selfdrive/controls/lib/latcontrol_torque.py
sed -i 's/^FRICTION_THRESHOLD = 0.2$/FRICTION_THRESHOLD = 0.275/' opendbc_repo/opendbc/car/lateral.py
sed -i 's/^"HYUNDAI_IONIQ_5" = \[3.172929, 2.713050, 0.096019\]$/"HYUNDAI_IONIQ_5" = [3.172929, 2.713050, 0.093138]/' opendbc_repo/opendbc/car/torque_data/params.toml

# 3. Commit and push
echo "[4/4] Committing and pushing..."
touch prebuilt
git add .
git commit -m "nightly + Ioniq 5 tune: $(date -u +%Y-%m-%d)" || echo "Nothing to commit"
GIT_LFS_SKIP_PUSH=1 git push -f origin $PREBUILT_BRANCH

echo "Done!"

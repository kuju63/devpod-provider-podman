#!/bin/bash
# Semantic Versioning Calculator
# Usage: semver.sh <current-version> <bump-type>
# Example: semver.sh v0.3.0 minor -> v0.4.0

set -euo pipefail

# Validate arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <current-version> <bump-type>" >&2
  echo "Example: $0 v0.3.0 minor" >&2
  exit 1
fi

current_version="$1"
bump_type="$2"

# Validate bump type
if [[ ! "$bump_type" =~ ^(major|minor|patch)$ ]]; then
  echo "Error: bump-type must be 'major', 'minor', or 'patch'" >&2
  exit 1
fi

# Parse version (handle with or without 'v' prefix)
if [[ "$current_version" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
else
  echo "Error: Invalid version format. Expected vX.Y.Z or X.Y.Z" >&2
  exit 1
fi

# Apply version bump
case "$bump_type" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
esac

# Output new version (always with 'v' prefix)
echo "v${major}.${minor}.${patch}"

#!/usr/bin/env bash
# prints ANDROID_VERSION_NAME and ANDROID_VERSION_CODE for a release tag, as shell assignments,
# or nothing if the tag is not v<major>.<minor>[.<patch>].
#
# Cargo.toml stays at 0.1.0, but the version code has to grow with every release: zapstore refuses
# one it has already published, and Android refuses to install an apk over a higher version code.
# The encoding is the one cargo-apk derives from Cargo.toml (1, major, minor, patch in the four
# bytes), so tag 0.1.0 and Cargo.toml 0.1.0 give the same code, 16777472.
set -euo pipefail

version="${1#v}"
if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))?$ ]]; then
    exit 0
fi
major=$((10#${BASH_REMATCH[1]}))
minor=$((10#${BASH_REMATCH[2]}))
patch=$((10#${BASH_REMATCH[4]:-0}))
for part in "$major" "$minor" "$patch"; do
    if ((part > 254)); then
        echo "version $version does not fit in a version code: $part is over 254" >&2
        exit 1
    fi
done
echo "ANDROID_VERSION_NAME=$version"
echo "ANDROID_VERSION_CODE=$(((1 << 24) | (major << 16) | (minor << 8) | patch))"

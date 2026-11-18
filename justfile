# build and run the desktop app
desktop:
    cargo run --bin bitcoin-smol

# build a debug apk for arm64 and install it on the connected device, without launching it.
# it's signed with release.jks (gitignored, password in release.jks.password), the same key as
# the github releases, so either can be installed over the other.
android-install:
    #!/usr/bin/env bash
    set -euo pipefail
    export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
    if [ -z "${ANDROID_NDK_ROOT:-}" ]; then
        export ANDROID_NDK_ROOT="$(ls -d "$ANDROID_HOME"/ndk/*/ | sort -V | tail -1)"
    fi
    export ANDROID_NDK="$ANDROID_NDK_ROOT"
    export CARGO_APK_DEV_KEYSTORE="$PWD/release.jks"
    export CARGO_APK_DEV_KEYSTORE_PASSWORD="$(cat release.jks.password)"
    # the version of the latest release, so this apk and the released one replace each other
    if tag="$(git describe --tags --abbrev=0 2>/dev/null)"; then
        version_env="$(android/version.sh "$tag")"
        if [ -n "$version_env" ]; then
            eval "$version_env"
            export ANDROID_VERSION_NAME ANDROID_VERSION_CODE
        fi
    fi
    cargo apk build --lib --target aarch64-linux-android
    android/package.sh ~/.cache/cargo-target/debug/apk/bitcoin-smol.apk "$CARGO_APK_DEV_KEYSTORE" "$CARGO_APK_DEV_KEYSTORE_PASSWORD"
    adb install -r ~/.cache/cargo-target/debug/apk/bitcoin-smol.apk

# serve the web build on http://127.0.0.1:8080, rebuilding on changes
web:
    trunk serve web/index.html

# render the screenshots for the readme and the user guide into docs/static/screenshots
screenshots:
    cargo run --release --features screenshots --bin screenshots

# publish the apk of a github release (default: the latest tag) to zapstore. needs the zapstore cli and a nostr signer (SIGN_WITH)
zapstore tag=`git describe --tags --abbrev=0`:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="$(mktemp -d)"
    trap 'rm -rf "$dir"' EXIT
    gh release download "{{tag}}" --pattern '*.apk' --dir "$dir"
    zapstore publish "$dir"/*.apk

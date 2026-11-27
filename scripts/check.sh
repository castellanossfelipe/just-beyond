#!/bin/sh
# Run before every push: core tests, then the app build for the simulator (unsigned).
# Install as a hook:  ln -s ../../scripts/check.sh .git/hooks/pre-push
set -eu
cd "$(git rev-parse --show-toplevel)"

echo "== Core tests"
swift test --package-path Packages/JBCore

echo "== App build (simulator, unsigned)"
xcodebuild build -project JustBeyond.xcodeproj -scheme JustBeyond \
  -destination 'generic/platform=iOS Simulator' \
  -quiet CODE_SIGNING_ALLOWED=NO

echo "All green."

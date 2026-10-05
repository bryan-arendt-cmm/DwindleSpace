#!/bin/zsh
# Build DwindleSpace from this checkout and install it the same way as on the
# original machine:
#   /Applications/AeroSpace.app   (release build, ad-hoc signed)
#   $(brew --prefix)/bin/aerospace (CLI)
#   ~/.aerospace.toml             (copied from config/aerospace.toml)
# plus the tools the config calls (JankyBorders, WezTerm).
#
# Usage: ./setup-new-machine.sh [--build-only]
# Prereqs: full Xcode (App Store, launched once) and Homebrew.
set -euo pipefail
cd "${0:A:h}"

build_only=0
case "${1:-}" in
    --build-only) build_only=1 ;;
    '') ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
esac

step() { print -P "\n%F{blue}==> $1%f"; }

#############
### DEPS ###
#############

step "Checking prerequisites"
if ! xcodebuild -version > /dev/null 2>&1; then
    echo "Full Xcode is required (Command Line Tools alone can't build the .app)." >&2
    echo "Install it from the App Store, launch it once, then run:" >&2
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
fi
if ! command -v brew > /dev/null; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
fi
brew_prefix="$(brew --prefix)"
export PATH="$brew_prefix/bin:$PATH" # generate.sh needs bash 5 first in PATH

step "Installing build deps (bash 5)"
brew list bash > /dev/null 2>&1 || brew install bash

if test $build_only = 0; then
    step "Installing tools used by the config (JankyBorders, WezTerm)"
    brew list borders > /dev/null 2>&1 || brew install FelixKratz/formulae/borders
    test -d /Applications/WezTerm.app || brew list --cask wezterm > /dev/null 2>&1 || brew install --cask wezterm
fi

#############
### BUILD ###
#############

# Restore the generated files even if the build fails
restore-generated() {
    git checkout -- xcode Sources/Common/versionGenerated.swift Sources/Common/gitHashGenerated.swift \
        Sources/Common/cmdHelpGenerated.swift Sources/Cli/subcommandDescriptionsGenerated.swift
}
trap restore-generated EXIT

step "Generating project (ad-hoc codesign, no certificate needed)"
./generate.sh --codesign-identity - --generate-git-hash

step "Building CLI"
swift build -c release --product aerospace

step "Building AeroSpace.app"
(cd xcode && xcodebuild clean build \
    -quiet \
    -scheme AeroSpace \
    -destination "generic/platform=macOS" \
    -configuration Release \
    -derivedDataPath .xcode-build)

rm -rf .release && mkdir .release
cp -R xcode/.xcode-build/Build/Products/Release/AeroSpace.app .release/
cp .build/release/aerospace .release/
codesign -s - --force .release/aerospace
codesign -v .release/AeroSpace.app .release/aerospace
echo "Built into .release/"

if test $build_only = 1; then exit 0; fi

###############
### INSTALL ###
###############

step "Installing app and CLI"
if brew list --cask aerospace > /dev/null 2>&1; then
    echo "Uninstalling stock aerospace cask (it would clash with this build)"
    brew uninstall --cask aerospace
fi
osascript -e 'quit app "AeroSpace"' 2> /dev/null || true
sleep 1
rm -rf /Applications/AeroSpace.app
cp -R .release/AeroSpace.app /Applications/
cp .release/aerospace "$brew_prefix/bin/aerospace"

step "Installing config"
config=~/.aerospace.toml
if test -f $config && ! cmp -s $config config/aerospace.toml; then
    backup="$config.bak.$(date +%Y%m%d%H%M%S)"
    mv $config "$backup"
    echo "Backed up existing config to $backup"
fi
cp config/aerospace.toml $config

step "Launching"
open /Applications/AeroSpace.app
cat << EOF

Done. Remaining manual steps:
  1. System Settings -> Privacy & Security -> Accessibility: enable AeroSpace
     (asked again after every rebuild, because the build is ad-hoc signed).
  2. Edit [workspace-to-monitor-force-assignment] in ~/.aerospace.toml if this
     machine's monitors aren't 'LG ULTRAWIDE' / 'DELL P2715Q'.
EOF

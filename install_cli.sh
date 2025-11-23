#!/bin/bash

# Installation script for NeutronX SDK and CLI
# This sets up NeutronX to work like the Flutter SDK

set -e

echo "Installing NeutronX SDK..."
echo ""

# Check if running from NeutronX root
if [ ! -f "packages/neutron_cli/pubspec.yaml" ]; then
    echo "Error: Must run from NeutronX root directory"
    exit 1
fi

# Get the absolute path to NeutronX
NEUTRONX_PATH="$(pwd)"

echo "→ Installing CLI dependencies..."
cd packages/neutron_cli
dart pub get
cd ../..

echo "→ Installing neutron command globally..."

# Install via dart pub global activate
dart pub global activate --source path packages/neutron_cli

echo ""
echo "✓ Installation complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 NeutronX SDK Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To use NeutronX as an SDK (like Flutter), add these to your"
echo "shell profile (~/.zshrc or ~/.bashrc):"
echo ""
echo "  export NEUTRONX_ROOT=\"$NEUTRONX_PATH\""
echo "  export PATH=\"\$PATH:\$HOME/.pub-cache/bin\""
echo ""
echo "Then reload your shell:"
echo "  source ~/.zshrc  # or source ~/.bashrc"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Usage:"
echo "  neutron new my_project    # Creates project with 'sdk: neutronx'"
echo "  neutron generate module users"
echo "  neutron dev"
echo ""
echo "See docs/SDK_SETUP.md for complete setup guide"
echo ""

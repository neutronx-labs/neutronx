#!/bin/bash

# Installation script for NeutronX CLI
# This script installs the neutron command globally

set -e

echo "Installing NeutronX CLI..."
echo ""

# Check if running from NeutronX root
if [ ! -f "packages/neutron_cli/pubspec.yaml" ]; then
    echo "Error: Must run from NeutronX root directory"
    exit 1
fi

# Install dependencies
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
echo "Make sure ~/.pub-cache/bin is in your PATH."
echo ""
echo "To add it, add this to your shell profile (~/.zshrc, ~/.bashrc):"
echo "  export PATH=\"\$PATH\":\$HOME/.pub-cache/bin"
echo ""
echo "Usage:"
echo "  neutron --help"
echo "  neutron new my_project"
echo "  neutron generate module users"
echo ""

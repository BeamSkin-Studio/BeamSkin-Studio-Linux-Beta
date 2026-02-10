#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "BeamSkin Studio - Linux Launcher"
echo "========================================="
echo ""

if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed!"
    echo ""
    echo "Please install Python 3 using your package manager:"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-tk"
    echo "  Fedora: sudo dnf install python3 python3-pip python3-tkinter"
    echo "  Arch: sudo pacman -S python python-pip tk"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

echo "Python 3 found: $(python3 --version)"
echo ""

if ! python3 -m pip --version &> /dev/null; then
    echo "ERROR: pip is not installed!"
    echo ""
    echo "Please install pip using your package manager:"
    echo "  Ubuntu/Debian: sudo apt install python3-pip"
    echo "  Fedora: sudo dnf install python3-pip"
    echo "  Arch: sudo pacman -S python-pip"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

echo "pip found: $(python3 -m pip --version)"
echo ""

echo "Checking dependencies..."

MISSING_DEPS=()

if ! python3 -c "import customtkinter" &> /dev/null; then
    MISSING_DEPS+=("customtkinter")
fi

if ! python3 -c "import PIL" &> /dev/null; then
    MISSING_DEPS+=("Pillow")
fi

if ! python3 -c "import requests" &> /dev/null; then
    MISSING_DEPS+=("requests")
fi

if [ ${
    echo "Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Would you like to install them now? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Installing dependencies..."
        python3 -m pip install --user customtkinter Pillow requests

        if [ $? -ne 0 ]; then
            echo ""
            echo "ERROR: Failed to install dependencies!"
            echo "Please try installing manually:"
            echo "  python3 -m pip install --user customtkinter Pillow requests"
            echo ""
            read -p "Press Enter to exit..."
            exit 1
        fi

        echo ""
        echo "Dependencies installed successfully!"
    else
        echo ""
        echo "Cannot run without required dependencies."
        echo "Please install them manually:"
        echo "  python3 -m pip install --user customtkinter Pillow requests"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

echo "All dependencies satisfied!"
echo ""

if ! python3 -c "import tkinter" &> /dev/null; then
    echo "WARNING: tkinter is not installed!"
    echo ""
    echo "tkinter is required for GUI support. Please install it using your package manager:"
    echo "  Ubuntu/Debian: sudo apt install python3-tk"
    echo "  Fedora: sudo dnf install python3-tkinter"
    echo "  Arch: sudo pacman -S tk"
    echo ""
    read -p "Press Enter to continue anyway (will likely fail)..."
fi

echo "Launching BeamSkin Studio..."
echo ""

python3 main.py

if [ $? -ne 0 ]; then
    echo ""
    echo "BeamSkin Studio exited with an error."
    read -p "Press Enter to exit..."
fi

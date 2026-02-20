#!/bin/bash

echo "============================================================"
echo "BeamSkin Studio - Linux Installation"
echo "============================================================"
echo ""

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "ERROR: This script is for Linux systems only!"
    echo "Current OS: $OSTYPE"
    exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    echo "Detected distribution: $NAME"
else
    echo "WARNING: Could not detect Linux distribution"
    DISTRO="unknown"
fi

echo ""

echo "[1/5] Checking Python 3 installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✓ Python 3 is installed: $PYTHON_VERSION"
else
    echo "✗ Python 3 is not installed!"
    echo ""
    echo "Installing Python 3..."

    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            echo "Using apt package manager..."
            sudo apt update
            sudo apt install -y python3 python3-pip python3-tk python3-venv
            ;;
        fedora|rhel|centos)
            echo "Using dnf/yum package manager..."
            sudo dnf install -y python3 python3-pip python3-tkinter
            ;;
        arch|manjaro)
            echo "Using pacman package manager..."
            sudo pacman -S --noconfirm python python-pip tk
            ;;
        opensuse*)
            echo "Using zypper package manager..."
            sudo zypper install -y python3 python3-pip python3-tk
            ;;
        *)
            echo "ERROR: Unsupported distribution!"
            echo "Please install Python 3 manually using your package manager."
            exit 1
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install Python 3!"
        exit 1
    fi

    echo "✓ Python 3 installed successfully"
fi

echo ""

echo "[2/5] Checking pip installation..."
if python3 -m pip --version &> /dev/null; then
    PIP_VERSION=$(python3 -m pip --version)
    echo "✓ pip is installed: $PIP_VERSION"
else
    echo "✗ pip is not installed!"
    echo ""
    echo "Installing pip..."

    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            sudo apt install -y python3-pip
            ;;
        fedora|rhel|centos)
            sudo dnf install -y python3-pip
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm python-pip
            ;;
        opensuse*)
            sudo zypper install -y python3-pip
            ;;
        *)
            python3 -m ensurepip --user
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install pip!"
        exit 1
    fi

    echo "✓ pip installed successfully"
fi

echo ""

echo "[3/5] Checking tkinter installation..."
if python3 -c "import tkinter" &> /dev/null 2>&1; then
    echo "✓ tkinter is installed"
else
    echo "✗ tkinter is not installed!"
    echo ""
    echo "Installing tkinter..."

    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            sudo apt install -y python3-tk
            ;;
        fedora|rhel|centos)
            sudo dnf install -y python3-tkinter
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm tk
            ;;
        opensuse*)
            sudo zypper install -y python3-tk
            ;;
        *)
            echo "ERROR: Please install tkinter manually for your distribution"
            exit 1
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install tkinter!"
        exit 1
    fi

    echo "✓ tkinter installed successfully"
fi

echo ""

echo "[4/6] Checking wmctrl installation (optional)..."
if command -v wmctrl &> /dev/null; then
    echo "✓ wmctrl is installed"
else
    echo "✗ wmctrl is not installed (optional, improves window management)"
    echo ""
    echo "Installing wmctrl..."

    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            sudo apt install -y wmctrl
            ;;
        fedora|rhel|centos)
            sudo dnf install -y wmctrl
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm wmctrl
            ;;
        opensuse*)
            sudo zypper install -y wmctrl
            ;;
        *)
            echo "⚠ Warning: Could not install wmctrl for your distribution"
            echo "  This is optional and won't affect core functionality."
            ;;
    esac

    if command -v wmctrl &> /dev/null; then
        echo "✓ wmctrl installed successfully"
    else
        echo "⚠ wmctrl installation skipped (optional feature)"
    fi
fi

echo ""

echo "[5/6] Upgrading pip to latest version..."
python3 -m pip install --user --upgrade pip
if [ $? -eq 0 ]; then
    echo "✓ pip upgraded successfully"
else
    echo "⚠ Warning: pip upgrade failed, continuing anyway..."
fi

echo ""

echo "[6/6] Installing Python dependencies..."
echo ""
echo "This may take a few minutes..."
echo ""

echo "Installing CustomTkinter (GUI framework)..."
python3 -m pip install --user customtkinter
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install customtkinter!"
    exit 1
fi
echo "✓ CustomTkinter installed"

echo "Installing Pillow (image processing)..."
python3 -m pip install --user Pillow
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Pillow!"
    exit 1
fi
echo "✓ Pillow installed"

echo "Installing requests (HTTP library)..."
python3 -m pip install --user requests
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install requests!"
    exit 1
fi
echo "✓ requests installed"

echo "Installing flagpy (flag emoji library)..."
python3 -m pip install --user flagpy
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install flagpy!"
    exit 1
fi
echo "✓ flagpy installed"

echo ""

echo "Verifying installations..."
echo ""

python3 -c "import customtkinter; print('✓ CustomTkinter version:', customtkinter.__version__)"
if [ $? -ne 0 ]; then
    echo "ERROR: CustomTkinter verification failed!"
    exit 1
fi

python3 -c "import PIL; print('✓ Pillow version:', PIL.__version__)"
if [ $? -ne 0 ]; then
    echo "ERROR: Pillow verification failed!"
    exit 1
fi

python3 -c "import requests; print('✓ Requests version:', requests.__version__)"
if [ $? -ne 0 ]; then
    echo "ERROR: Requests verification failed!"
    exit 1
fi

python3 -c "import flag; print('✓ flagpy is available')"
if [ $? -ne 0 ]; then
    echo "ERROR: flagpy verification failed!"
    exit 1
fi

python3 -c "import tkinter; print('✓ tkinter is available')"
if [ $? -ne 0 ]; then
    echo "ERROR: tkinter verification failed!"
    exit 1
fi

echo ""
echo "============================================================"
echo "Installation Complete!"
echo "============================================================"
echo ""
echo "All required dependencies have been installed successfully."
echo ""
echo "To run BeamSkin Studio:"
echo "  ./beamskin_studio.sh"
echo ""
echo "Or:"
echo "  python3 main.py"
echo ""

if [ -f "beamskin_studio.sh" ]; then
    chmod +x beamskin_studio.sh
    echo "Made launcher script executable."
    echo ""
fi

read -p "Would you like to launch BeamSkin Studio now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Launching BeamSkin Studio..."
    sleep 1

    if [ -f "beamskin_studio.sh" ]; then
        ./beamskin_studio.sh
    else
        python3 main.py
    fi
fi
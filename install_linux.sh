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

# -----------------------------------------------------------------------
# Python discovery
#
# Checks PATH first for common interpreter names/versions, then falls
# back to scanning typical install locations on disk - pyenv, alt
# installs, /opt/python*, snap, etc. - for systems where python3 exists
# but isn't (fully) registered on PATH. Only if nothing is found at all
# do we fall through to installing a fresh Python via the package manager.
# -----------------------------------------------------------------------

PYEXE=""

PATH_CANDIDATES=(python3.13 python3.12 python3.11 python3.10 python3.9 python3)

DISK_GLOBS=(
    "/usr/bin/python3.*"
    "/usr/local/bin/python3.*"
    "/opt/python3*/bin/python3*"
    "/opt/python*/bin/python3*"
    "$HOME/.pyenv/versions/*/bin/python3*"
    "$HOME/.local/bin/python3.*"
    "/snap/bin/python3*"
)

is_valid_python() {
    local cand="$1"
    [ -x "$cand" ] || command -v "$cand" &> /dev/null || return 1
    "$cand" -c "import sys; exit(0 if sys.version_info>=(3,9) else 1)" &> /dev/null
}

echo "[1/6] Checking for an existing Python 3.9+ installation..."

for cand in "${PATH_CANDIDATES[@]}"; do
    if [ -z "$PYEXE" ] && command -v "$cand" &> /dev/null && is_valid_python "$cand"; then
        PYEXE="$cand"
    fi
done

if [ -z "$PYEXE" ]; then
    shopt -s nullglob
    for pattern in "${DISK_GLOBS[@]}"; do
        for cand in $pattern; do
            [ -x "$cand" ] || continue
            base="$(basename "$cand")"
            [[ "$base" =~ ^python3(\.[0-9]+)?$ ]] || continue
            if is_valid_python "$cand"; then
                PYEXE="$cand"
                break
            fi
        done
        [ -n "$PYEXE" ] && break
    done
    shopt -u nullglob
fi

if [ -n "$PYEXE" ]; then
    PYTHON_VERSION=$("$PYEXE" --version 2>&1)
    echo "✓ Found Python 3: $PYTHON_VERSION ($PYEXE)"
else
    echo "✗ No usable Python 3 (3.9+) found on PATH or in common install locations!"
    echo ""
    echo "Installing Python 3 via package manager..."

    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            echo "Using apt package manager..."
            sudo apt update
            sudo apt install -y python3 python3-pip python3-venv
            ;;
        fedora|rhel|centos)
            echo "Using dnf/yum package manager..."
            sudo dnf install -y python3 python3-pip
            ;;
        arch|manjaro)
            echo "Using pacman package manager..."
            sudo pacman -S --noconfirm python python-pip
            ;;
        opensuse*)
            echo "Using zypper package manager..."
            sudo zypper install -y python3 python3-pip
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

    # Re-probe now that a package-manager install should have landed on PATH
    for cand in "${PATH_CANDIDATES[@]}"; do
        if [ -z "$PYEXE" ] && command -v "$cand" &> /dev/null && is_valid_python "$cand"; then
            PYEXE="$cand"
        fi
    done

    if [ -z "$PYEXE" ]; then
        echo "ERROR: Python 3 install appeared to succeed, but no usable interpreter was found afterward!"
        exit 1
    fi

    PYTHON_VERSION=$("$PYEXE" --version 2>&1)
    echo "✓ Python 3 installed successfully: $PYTHON_VERSION"
fi

echo ""

echo "[2/6] Checking pip installation..."
if "$PYEXE" -m pip --version &> /dev/null; then
    PIP_VERSION=$("$PYEXE" -m pip --version)
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
            "$PYEXE" -m ensurepip --user
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install pip!"
        exit 1
    fi

    echo "✓ pip installed successfully"
fi

echo ""

echo "[3/6] Checking libGL (required for PySide6/Qt rendering)..."
if ldconfig -p 2>/dev/null | grep -q "libGL.so.1"; then
    echo "✓ libGL is available"
else
    echo "✗ libGL not found - installing..."

    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            sudo apt install -y libgl1
            ;;
        fedora|rhel|centos)
            sudo dnf install -y mesa-libGL
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm mesa
            ;;
        opensuse*)
            sudo zypper install -y Mesa-libGL1
            ;;
        *)
            echo "⚠ Warning: Please install libGL manually for your distribution"
            ;;
    esac
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
"$PYEXE" -m pip install --user --upgrade pip
if [ $? -eq 0 ]; then
    echo "✓ pip upgraded successfully"
else
    echo "⚠ Warning: pip upgrade failed, continuing anyway..."
fi

echo ""

echo "[6/6] Installing Python dependencies from requirements.txt..."
echo ""
echo "This may take a few minutes..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    "$PYEXE" -m pip install --user -r "$SCRIPT_DIR/requirements.txt"
    if [ $? -ne 0 ]; then
        echo ""
        echo "ERROR: Failed to install dependencies from requirements.txt!"
        exit 1
    fi
    echo "✓ Dependencies installed from requirements.txt"
else
    echo "⚠ requirements.txt not found - falling back to hardcoded package list"
    "$PYEXE" -m pip install --user "PySide6>=6.5.0" "Pillow>=10.0.0" "imageio>=2.28.0" "requests>=2.31.0"
    if [ $? -ne 0 ]; then
        echo ""
        echo "ERROR: Failed to install dependencies!"
        exit 1
    fi
    echo "✓ Dependencies installed"
fi

echo ""

echo "Verifying installations..."
echo ""

"$PYEXE" -c "import PySide6; print('✓ PySide6 version:', PySide6.__version__)"
if [ $? -ne 0 ]; then
    echo "ERROR: PySide6 verification failed!"
    exit 1
fi

"$PYEXE" -c "import PIL; print('✓ Pillow version:', PIL.__version__)"
if [ $? -ne 0 ]; then
    echo "ERROR: Pillow verification failed!"
    exit 1
fi

"$PYEXE" -c "import imageio; print('✓ imageio version:', imageio.__version__)"
if [ $? -ne 0 ]; then
    echo "ERROR: imageio verification failed!"
    exit 1
fi

"$PYEXE" -c "import requests; print('✓ Requests version:', requests.__version__)"
if [ $? -ne 0 ]; then
    echo "ERROR: Requests verification failed!"
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
echo "  $PYEXE main.py"
echo ""

if [ -f "$SCRIPT_DIR/beamskin_studio.sh" ]; then
    chmod +x "$SCRIPT_DIR/beamskin_studio.sh"
    echo "Made launcher script executable."
    echo ""
fi

read -p "Would you like to launch BeamSkin Studio now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Launching BeamSkin Studio..."
    sleep 1

    if [ -f "$SCRIPT_DIR/beamskin_studio.sh" ]; then
        "$SCRIPT_DIR/beamskin_studio.sh"
    else
        "$PYEXE" main.py
    fi
fi

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "BeamSkin Studio - Linux Launcher"
echo "========================================="
echo ""

# -----------------------------------------------------------------------
# Python discovery
#
# Mirrors the Windows .bat probing chain (py -3.13 ... py -3.9, then
# plain "python"), but for Linux: checks PATH first for common interpreter
# names/versions, then falls back to scanning typical install locations
# on disk for systems where python3 isn't (or isn't fully) on PATH -
# pyenv, deadsnakes/apt alt-installs, /opt/python*, manually built
# interpreters, etc.
# -----------------------------------------------------------------------

PYEXE=""

# Candidate names to check on PATH, newest-preferred (matches the .bat order)
PATH_CANDIDATES=(python3.13 python3.12 python3.11 python3.10 python3.9 python3 python)

# Candidate directories to scan on disk when nothing usable is on PATH.
# Globs are expanded below; nonexistent paths are simply skipped.
DISK_GLOBS=(
    "/usr/bin/python3.*"
    "/usr/local/bin/python3.*"
    "/opt/python3*/bin/python3*"
    "/opt/python*/bin/python3*"
    "$HOME/.pyenv/versions/*/bin/python3*"
    "$HOME/.local/bin/python3.*"
    "/snap/bin/python3*"
)

# Checks that a candidate is executable AND has our required deps.
# If a bare interpreter exists but is missing deps, we still remember it
# as a fallback so install.sh has something to install into.
FALLBACK_PYEXE=""

check_candidate() {
    local cand="$1"
    if ! command -v "$cand" &> /dev/null && [ ! -x "$cand" ]; then
        return 1
    fi
    if ! "$cand" -c "import sys; exit(0 if sys.version_info>=(3,9) else 1)" &> /dev/null; then
        return 1
    fi
    if [ -z "$FALLBACK_PYEXE" ]; then
        FALLBACK_PYEXE="$cand"
    fi
    if "$cand" -c "import PySide6, PIL, requests, imageio" &> /dev/null; then
        PYEXE="$cand"
        return 0
    fi
    return 1
}

echo "Detecting compatible Python installation..."

# 1) Try PATH first (fast path, covers the vast majority of systems)
for cand in "${PATH_CANDIDATES[@]}"; do
    if [ -z "$PYEXE" ] && command -v "$cand" &> /dev/null; then
        check_candidate "$cand"
    fi
done

# 2) Not on PATH (or PATH version is missing deps) - scan common install
#    locations on disk directly by absolute path.
if [ -z "$PYEXE" ]; then
    shopt -s nullglob
    for pattern in "${DISK_GLOBS[@]}"; do
        for cand in $pattern; do
            # Skip symlinks to already-checked names and non-executables
            [ -x "$cand" ] || continue
            # Skip *-config, *-gdb.py, idle3, etc. that also match the glob
            base="$(basename "$cand")"
            [[ "$base" =~ ^python3(\.[0-9]+)?$ ]] || continue
            check_candidate "$cand"
            [ -n "$PYEXE" ] && break
        done
        [ -n "$PYEXE" ] && break
    done
    shopt -u nullglob
fi

if [ -n "$PYEXE" ]; then
    echo "✓ Using Python: $PYEXE ($("$PYEXE" --version 2>&1))"
    echo ""
else
    # Nothing has all deps. Fall back to whatever interpreter we found
    # (PATH or disk) so we can offer to install into it; otherwise bail.
    if [ -z "$FALLBACK_PYEXE" ]; then
        for cand in "${PATH_CANDIDATES[@]}"; do
            if command -v "$cand" &> /dev/null; then
                if "$cand" -c "import sys; exit(0 if sys.version_info>=(3,9) else 1)" &> /dev/null; then
                    FALLBACK_PYEXE="$cand"
                    break
                fi
            fi
        done
    fi

    if [ -z "$FALLBACK_PYEXE" ]; then
        shopt -s nullglob
        for pattern in "${DISK_GLOBS[@]}"; do
            for cand in $pattern; do
                [ -x "$cand" ] || continue
                base="$(basename "$cand")"
                [[ "$base" =~ ^python3(\.[0-9]+)?$ ]] || continue
                if "$cand" -c "import sys; exit(0 if sys.version_info>=(3,9) else 1)" &> /dev/null; then
                    FALLBACK_PYEXE="$cand"
                    break
                fi
            done
            [ -n "$FALLBACK_PYEXE" ] && break
        done
        shopt -u nullglob
    fi

    if [ -z "$FALLBACK_PYEXE" ]; then
        echo "ERROR: No Python 3.9+ installation could be found!"
        echo ""
        echo "Checked PATH for: ${PATH_CANDIDATES[*]}"
        echo "Checked disk locations including pyenv, /opt, /usr/local, and snap installs."
        echo ""
        echo "Please install Python 3 using your package manager, or run ./install_linux.sh"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi

    PYEXE="$FALLBACK_PYEXE"
    echo "Found Python at: $PYEXE ($("$PYEXE" --version 2>&1)), but required packages are missing."
    echo ""
fi

echo "Checking dependencies..."

MISSING_DEPS=()

if ! "$PYEXE" -c "import PySide6" &> /dev/null; then
    MISSING_DEPS+=("PySide6")
fi

if ! "$PYEXE" -c "import PIL" &> /dev/null; then
    MISSING_DEPS+=("Pillow")
fi

if ! "$PYEXE" -c "import imageio" &> /dev/null; then
    MISSING_DEPS+=("imageio")
fi

if ! "$PYEXE" -c "import requests" &> /dev/null; then
    MISSING_DEPS+=("requests")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Would you like to install them now? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Installing dependencies..."
        if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
            "$PYEXE" -m pip install --user -r "$SCRIPT_DIR/requirements.txt"
        else
            "$PYEXE" -m pip install --user PySide6 Pillow imageio requests
        fi

        if [ $? -ne 0 ]; then
            echo ""
            echo "ERROR: Failed to install dependencies!"
            echo "Please try running: ./install_linux.sh"
            echo ""
            read -p "Press Enter to exit..."
            exit 1
        fi

        echo ""
        echo "Dependencies installed successfully!"
    else
        echo ""
        echo "Cannot run without required dependencies."
        echo "Please run: ./install_linux.sh"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

echo "All dependencies satisfied!"
echo ""

if ! ldconfig -p 2>/dev/null | grep -q "libGL.so.1"; then
    echo "WARNING: libGL was not found!"
    echo ""
    echo "libGL is required for PySide6/Qt rendering. Please install it using your package manager:"
    echo "  Ubuntu/Debian: sudo apt install libgl1"
    echo "  Fedora: sudo dnf install mesa-libGL"
    echo "  Arch: sudo pacman -S mesa"
    echo ""
    read -p "Press Enter to continue anyway (will likely fail)..."
fi

echo "Launching BeamSkin Studio..."
echo ""

"$PYEXE" main.py

if [ $? -ne 0 ]; then
    echo ""
    echo "BeamSkin Studio exited with an error."
    read -p "Press Enter to exit..."
fi

# BeamSkin Studio - Linux

## Installation

1. **Download BeamSkin Studio**
- Download zip from release



2. **Extract ZIP**
- extract it to where you want to have BeamSkin Studio



3. Run the install_linux.sh file
- Open a terminal in the BeamSkin Studio folder
- Make the installer executable: `chmod +x install_linux.sh`
- Run the installer: `./install_linux.sh`
- It will install everything that is required to run BeamSkin Studio



4. after everything is installed
- after the install is done, you can launch BeamSkin Studio using `./beamskin_studio.sh`
- Alternatively, run directly with: `python3 main.py`




## Desktop Integration (Optional)

To add BeamSkin Studio to your application menu:

1. Edit the `beamskin-studio.desktop` file
- Change `/path/to/BeamSkin-Studio/` to your actual installation path (both Exec and Icon lines)

2. Copy to applications folder:
- `mkdir -p ~/.local/share/applications`
- `cp beamskin-studio.desktop ~/.local/share/applications/`

3. Make it executable:
- `chmod +x ~/.local/share/applications/beamskin-studio.desktop`

BeamSkin Studio should now appear in your application menu!




## Updating
- if u are updating to a new version, extract the new version over your current BeamSkin Studio folder
- You may need to rerun `./install_linux.sh` if dependencies have changed




## Features

- Automatic update checking (checks GitHub for new versions on startup)
- Current version is pulled from `version.txt`




## Troubleshooting

**Permission Denied Errors:** If you get "Permission denied" when trying to run scripts, make them executable with `chmod +x <script_name>.sh`

**Missing Dependencies:** If you get `ModuleNotFoundError`, run the installer again: `./install_linux.sh`

**tkinter Issues:** If tkinter is not found, install it manually:
- Ubuntu/Debian: `sudo apt install python3-tk`
- Fedora: `sudo dnf install python3-tkinter`
- Arch: `sudo pacman -S tk`

**Display Issues:** If you experience window management issues, install wmctrl:
- Ubuntu/Debian: `sudo apt install wmctrl`
- Fedora: `sudo dnf install wmctrl`
- Arch: `sudo pacman -S wmctrl`

**Reporting Issues:** if you get errors, please submit what error you are getting on github > issues and tell me how I can replicate it
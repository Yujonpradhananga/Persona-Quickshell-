<h1 align=center>Persona Quickshell</h1>

<div align=center>

[![QML](https://img.shields.io/badge/QML-Quickshell-7aa2f7?style=for-the-badge&logo=qt&logoColor=white)](https://quickshell.outfoxxed.me)
[![Stars](https://img.shields.io/github/stars/Yujonpradhananga/Persona-Quickshell-?style=for-the-badge&color=e0af68&logoColor=white)](https://github.com/Yujonpradhananga/Persona-Quickshell-/stargazers)
[![Hyprland](https://img.shields.io/badge/Hyprland-supported-2ac3de?style=for-the-badge&logoColor=white)](https://hyprland.org)
[![NixOS](https://img.shields.io/badge/NixOS-compatible-7dcfff?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Last Commit](https://img.shields.io/github/last-commit/Yujonpradhananga/Persona-Quickshell-?style=for-the-badge&color=9ece6a&logoColor=white)](https://github.com/Yujonpradhananga/Persona-Quickshell-/commits/main)

</div>

A custom Quickshell configuration themed after Persona 3 reload.
Hyprland and MangoWC window manager support

# Demo

<https://github.com/user-attachments/assets/78e3685d-7643-4e5e-ab2d-d2b7f1a44dbb>

# Dependencies

## plugins

A hyprland monitor plugin has been used for the workspace overview implementation.
The repo to download and build is here, just follow its instructions:
<https://github.com/Happilli/HyprlandMonitor/tree/main>

if you dont want to mannually build it and go through the installation you can use the old method, by replacing all the instances of Mousemover with Mousemoverold in the AppLauncher.qml file

## fonts used

-Linux Biolinum. \
-Montserrat. \
-Glirock.

# AppLauncher

The AppLauncher requires a hyprland keybind for it to work

## Keybind

bind = $mainMod, R, exec, quickshell -c /Location to where its installed/ ipc call searchapp toggle
Mine is set like this:
bind = $mainMod, R, exec, quickshell -c /home/yujon/Projects/quickshell/ ipc call searchapp toggle

## Vim motion

You can move up and down the AppLauncher with ctrl+k and ctrl+j and the mouse as well. You can also search for apps but the search bar is hidden for aesthetics lolz.

# For MangoWC support

replace the Mousemover.qml in the OnClicked in the AppDrawer.qml file to the Mousemoverwlroots.qml

# Power menu

the power menu currently uses loginctl commands, feel free to change them to your needs.

# Credits

Inspiration taken from:
<https://github.com/RyuZinOh/.dotfiles>
shader taken from:
<https://github.com/eq-desktop/Vitreus>

#

Not perfect, certain modules can be optimized better. Feel free to pr and suggest improvements.
thnx for checking it out

## License

MIT License - feel free to use and modify as needed.
Created by Yujon Pradhananga

#!/usr/bin/env bash

if [[ $EUID -eq 0 ]]; then
  echo "This script should not be executed as root! Exiting..."
  exit 1
fi

if [[ ! "$(grep -i nixos </etc/os-release)" ]]; then
  echo "This installation script only works on NixOS! Download an iso at https://nixos.org/download/"
  echo "Keep in mind that this script is not intended for use while in the live environment."
  exit 1
fi

if [ -d "$HOME/NixOS" ]; then
  flake=$HOME/NixOS
elif [ -d "/etc/nixos/hosts/Default" ]; then
  flake=/etc/nixos
else
  echo "Error: flake not found. ensure flake.nix exists in either $HOME/NixOS or /etc/nixos"
  exit 1
fi
currentUser=$(logname)

# replace username variable in flake.nix with $USER
sed -i -e "s/username = \".*\"/username = \"$currentUser\"/" "$flake/flake.nix"

if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
  cat "/etc/nixos/hardware-configuration.nix" >"$flake/hosts/Default/hardware-configuration.nix"
elif [ -f "/etc/nixos/hosts/Default/hardware-configuration.nix" ]; then
  cat "/etc/nixos/hosts/Default/hardware-configuration.nix" >"$flake/hosts/Default/hardware-configuration.nix"
else
  read -p "No hardware config found, generate another? (Y/n): " confirm
  if [[ "$confirm" =~ ^[nN]$ ]]; then
    echo "Aborted."
    exit 1
  fi
  clear
  nix develop "$flake" --command bash -c "echo GENERATING CONFIG! | figlet -cklno | lolcat -F 0.3 -p 2.5 -S 300"
  sudo nixos-generate-config --show-hardware-config >"$flake/hosts/Default/hardware-configuration.nix"
fi

sudo git -C "$flake" add hosts/Default/hardware-configuration.nix

# nh os switch "$flake"
sudo nixos-rebuild switch --flake "$flake"
# rm "$flake"/hosts/Default/hardware-configuration.nix &>/dev/null
# git restore --staged "$flake"/hosts/Default/hardware-configuration.nix &>/dev/null

echo
read -rsn1 -p"Press any key to continue"

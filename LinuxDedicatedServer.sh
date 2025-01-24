#!/bin/sh
echo -ne '\033c\033]0;Godot 4 Multiplayer Server\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/LinuxDedicatedServer.x86_64" "$@"

#!/bin/bash

colorize() {
    local color="$1"; shift
    case "$color" in
        red) echo -e "\e[91m$*\e[0m" ;;
        green) echo -e "\e[92m$*\e[0m" ;;
        yellow) echo -e "\e[93m$*\e[0m" ;;
        blue) echo -e "\e[94m$*\e[0m" ;;
        *) echo "$*";;
    esac
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

check_dependencies() {
    local REQUIRED_CMDS=(ffmpeg jq bc stat)
    local missing=()

    for cmd in "${REQUIRED_CMDS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done

    if (( ${#missing[@]} > 0 )); then
        echo "🔍 Missing dependencies: ${missing[*]}"
        read -rp "❓ Install them now? (y/n): " INSTALL
        [[ "$INSTALL" != "y" ]] && { echo "❌ Exiting."; exit 1; }

        if command -v pacman >/dev/null; then
            sudo pacman -S --noconfirm "${missing[@]}"
        elif command -v yay >/dev/null; then
            yay -S --noconfirm "${missing[@]}"
        elif command -v paru >/dev/null; then
            paru -S --noconfirm "${missing[@]}"
        else
            echo "❌ No supported package manager (pacman/yay/paru)"
            exit 1
        fi

        for cmd in "${missing[@]}"; do
            command -v "$cmd" >/dev/null 2>&1 || {
                echo "❌ $cmd failed to install. Exiting."
                exit 1
            }
        done

        echo "✅ Dependencies installed."
    fi
}

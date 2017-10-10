#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="ccache"
rp_module_desc="Compiler cache (ccache) configuration"
rp_module_section="config"

function enable_ccache() {
    [[ ! "$(which ccache)" ]] && aptInstall ccache
    touch "$__ccache_enable"
    ccache_update_env
}

function disable_ccache() {
    [[ -f "$__ccache_enable" ]] && rm "$__ccache_enable"
    ccache_update_env
}

function clear_ccache() {
    [[ ! "$(which ccache)" ]] && return

    ccache -C
}

function stats_ccache() {
    [[ ! "$(which ccache)" ]] && return

    local type="$1"
    [[ "$type" == "" ]] && type="console"
    printMsgs "$type" "$(ccache -s)"
}

function ccache_update_env() {
    if [[ -f "$__ccache_enable" ]]; then
        [[ ! "$(echo $PATH | grep /usr/lib/ccache)" ]] && export PATH="/usr/lib/ccache:$PATH"
    else
        export PATH=$(echo "$PATH" | sed 's/\/usr\/lib\/ccache\://g')
    fi
}

function ccache_print_summary() {
    local cache_size
    local max_cache_size
    local hit_rate

    if [[ "$1" == "not installed" ]]; then
        echo "(ccache statistics not available)\n"
    else
        cache_size=$(ccache -s | grep -m1 "cache size" | awk '{ print $(NF-1),$NF }')
        max_cache_size=$(ccache -s | grep -m1 "max cache size" | awk '{ print $(NF-1),$NF }')
        hit_rate=$(ccache -s | grep -m1 "cache hit rate" | awk '{ print $(NF-1),$NF }')
        echo "cache usage: $cache_size (of $max_cache_size), $hit_rate hit rate\n"
    fi
}

function gui_ccache() {
    local is_enabled

    while true; do
        is_enabled="disabled"
        [[ -f "$__ccache_enable" ]] && is_enabled="enabled"
        [[ ! "$(which ccache)" ]] && is_enabled="not installed"

        local cmd=(dialog --backtitle "$__backtitle" --menu "Compiler cache (ccache) configuration\n\n$(ccache_print_summary "$is_enabled")" 22 76 16)
        local options=(
            1 "Toggle ccache (current: $is_enabled)"
            2 "Clear cache"
            3 "Show statistics"
        )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    if [[ "$is_enabled" == "enabled" ]]; then
                        rp_callModule "$md_id" disable
                    else
                        rp_callModule "$md_id" enable
                    fi
                    ;;
                2)
                    rp_callModule "$md_id" clear
                    ;;
                3)
                    rp_callModule "$md_id" stats dialog
                    ;;
            esac
        else
            break
        fi
    done
}

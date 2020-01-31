#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="dosbox"
rp_module_desc="DOS emulator"
rp_module_help="ROM Extensions: .bat .com .exe .sh .conf\n\nCopy your DOS games to $romdir/pc"
rp_module_licence="GPL2 https://sourceforge.net/p/dosbox/code-0/HEAD/tree/dosbox/trunk/COPYING"
rp_module_section="opt"
rp_module_flags="dispmanx sdl1"

function depends_dosbox() {
    local depends=(libsdl1.2-dev libsdl-net1.2-dev libsdl-sound1.2-dev libasound2-dev libpng-dev automake autoconf zlib1g-dev subversion "$@")
    isPlatform "rpi" && depends+=(timidity freepats)
    getDepends "${depends[@]}"
}

function sources_dosbox() {
    local revision="$1"
    [[ -z "$revision" ]] && revision="4252"

    svn checkout https://svn.code.sf.net/p/dosbox/code-0/dosbox/trunk "$md_build" -r "$revision"
    applyPatch "$md_data/01-fully-bindable-joystick.diff"
}

function build_dosbox() {
    local params=()

    ! isPlatform "x11" && params+=(--disable-opengl)
    # add or override params from calling function
    params+=("$@")

    ./autogen.sh
    ./configure --prefix="$md_inst" "${params[@]}"
    if isPlatform "arm"; then
        # enable dynamic recompilation for armv4
        sed -i 's|/\* #undef C_DYNREC \*/|#define C_DYNREC 1|' config.h
        if isPlatform "armv6"; then
            sed -i 's/C_TARGETCPU.*/C_TARGETCPU ARMV4LE/g' config.h
        else
            sed -i 's/C_TARGETCPU.*/C_TARGETCPU ARMV7LE/g' config.h
            sed -i 's|/\* #undef C_UNALIGNED_MEMORY \*/|#define C_UNALIGNED_MEMORY 1|' config.h
        fi
    fi
    make clean
    make
    md_ret_require="$md_build/src/dosbox"
}

function install_dosbox() {
    make install
    md_ret_require="$md_inst/bin/dosbox"
}

function configure_dosbox() {
    local launcher_script="$md_inst/bin/dosbox.sh"
    local start_script="$romdir/pc/+Start DOSBox.sh"

    if [[ "$md_id" == "dosbox-sdl2" ]]; then
        local def="0"
        local needs_synth="0"
    else
        local def="1"
        # needs software synth for midi; limit to Pi for now
        if isPlatform "rpi"; then
            local needs_synth="1"
        fi
    fi

    mkRomDir "pc"
    rm -f "$start_script"
    if [[ "$md_mode" == "install" ]]; then
        cat > "$start_script" << _EOF_
#!/bin/bash
$rootdir/supplementary/runcommand/runcommand.sh 0 _SYS_ pc
_EOF_

        cat > "$launcher_script" << _EOF_
#!/bin/bash

[[ ! -n "\$(aconnect -o | grep -e TiMidity -e FluidSynth)" ]] && needs_synth="$needs_synth"

function midi_synth() {
    [[ "\$needs_synth" != "1" ]] && return

    case "\$1" in
        "start")
            timidity -Os -iAD &
            until [[ -n "\$(aconnect -o | grep TiMidity)" ]]; do
                sleep 1
            done
            ;;
        "stop")
            killall timidity
            ;;
        *)
            ;;
    esac
}

params=("\$@")
if [[ -z "\${params[0]}" ]]; then
    params=(-c "@MOUNT C $romdir/pc" -c "@C:")
elif [[ "\${params[0]}" == *.sh ]]; then
    midi_synth start
    bash "\${params[@]}"
    midi_synth stop
    exit
elif [[ "\${params[0]}" == *.conf ]]; then
    params=(-userconf -conf "\${params[@]}")
else
    params+=(-exit)
fi

midi_synth start
"$md_inst/bin/dosbox" "\${params[@]}"
midi_synth stop
_EOF_
        chmod +x "$launcher_script" "$start_script"
        chown $user:$user "$start_script"

        local config_path=$(su "$user" -c "\"$md_inst/bin/dosbox\" -printconf")
        if [[ -f "$config_path" ]]; then
            iniConfig " = " "" "$config_path"
            iniSet "usescancodes" "false"
            iniSet "core" "dynamic"
            iniSet "cycles" "max"
            iniSet "scaler" "none"
            if isPlatform "rpi" || [[ -n "$(aconnect -o | grep -e TiMidity -e FluidSynth)" ]]; then
                iniSet "mididevice" "alsa"
                iniSet "midiconfig" "128:0"
            fi
            if isPlatform "mesa"; then
                iniSet "fullscreen" "true"
                iniSet "fullresolution" "desktop"
                iniSet "output" "overlay"
            fi
        fi
    fi

    moveConfigDir "$home/.$md_id" "$md_conf_root/pc"

    addEmulator "$def" "$md_id" "pc" "bash ${launcher_script// /\\ } %ROM%"
    addSystem "pc"
}

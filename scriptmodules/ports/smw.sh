#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="smw"
rp_module_desc="Super Mario War"
rp_module_licence="GPL http://supermariowar.supersanctuary.net/"
rp_module_section="opt"
rp_module_flags=""

function depends_smw() {
    getDepends libsdl2-dev libsdl2-mixer-dev libsdl2-image-dev zlib1g-dev
}

function sources_smw() {
    gitPullOrClone "$md_build" https://github.com/mmatyas/supermariowar
    applyPatch "$md_data/0001-avoid-atexit.patch"
    applyPatch "$md_data/0002-enable-vsync.patch"
    unzip -o data.zip
}

function build_smw() {
    local params=(-DUSE_SDL2_LIBS=1 -DDISABLE_DEFAULT_CFLAGS=1)
    isPlatform "gles" && params+=(-DSDL2_FORCE_GLES=1)

    cmake . -DCMAKE_INSTALL_PREFIX="$md_inst" ${params[@]}
    make clean
    make

    md_ret_require="$md_build/Binaries/Release/$md_id"
}

function install_smw() {
    md_ret_files=(
        'data'
        'Binaries/Release/smw'
        'Binaries/Release/smw-leveledit'
        'Binaries/Release/smw-server'
        'Binaries/Release/smw-worldedit'
        'README.md'
    )
}

function configure_smw() {
    addPort "$md_id" "smw" "Super Mario War" "$md_inst/smw $md_inst/data"
    addPort "$md_id" "smw-level" "Super Mario War - Level Editor" "$md_inst/smw-leveledit $md_inst/data"
    addPort "$md_id" "smw-world" "Super Mario War - World Editor" "$md_inst/smw-worldedit $md_inst/data"

    moveConfigDir "$home/.smw" "$md_conf_root/$md_id"
}

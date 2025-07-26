FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:plds-verdin-imx8mp-canopus = " \
            file://config/verdin-imx8mp-canopus_defconfig \
            file://patches/0001-adding-canopus-board-as-fdt-board.patch"           

do_patchextra() {
    if [ "${MACHINE}" == "plds-verdin-imx8mp-canopus" ]
    then
        install -m 0644 ${WORKDIR}/config/verdin-imx8mp-canopus_defconfig ${S}/configs/
    fi
}

addtask patchextra after do_patch before do_compile
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:plds-verdin-imx8mp-canopus = " \
            file://config/verdin-imx8mp-canopus_defconfig \
            file://patches/0001-uboot-variable-adjust-for-Canopus-board.patch \
            file://patches/0002-uboot-canopus-eg91-vbat.patch"

SRC_URI:append:verdin-imx8mp = " \
            file://patches/0003-uboot-variable-adjust-for-yavia-board.patch \
            file://patches/0004-adding-vfat-config-to-verdin-imx8mp.patch "
            

do_patchextra() {
    if [ "${MACHINE}" == "plds-verdin-imx8mp-canopus" ]
    then
        install -m 0644 ${WORKDIR}/config/verdin-imx8mp-canopus_defconfig ${S}/configs/
    fi
}

addtask patchextra after do_patch before do_compile
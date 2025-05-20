FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

unset KBUILD_DEFCONFIG

SRC_URI:append:plds-verdin-imx8mp-canopus = " \
            file://defconfig \
            file://dts/canopus/imx8mp-verdin-canopus.dtsi \
            file://dts/canopus/imx8mp-verdin-wifi-canopus.dtsi \
            file://dts/canopus/imx8mp-verdin-wifi-canopus.dts \
            file://patches/0001-fixing-imx219-init.patch \
            file://patches/0001-imx219-fixing-spower-function.patch \
            file://patches/0001-fixing-raw-output-on-isi.patch \
            file://patches/0001-changing-default-video-input-formats.patch"

SRC_URI:append:verdin-imx8mp = " \
            file://defconfig \
            file://dts/yavia/imx8mp-verdin-yavia.dtsi \
            file://patches/0001-adding-debug-max6897.patch"

do_patchextra() {
    install -d ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/freescale

    if [ "${MACHINE}" == "plds-verdin-imx8mp-canopus" ]
    then
        echo "installing ${MACHINE} dts..."
        install -m 0644 ${WORKDIR}/dts/canopus/imx8mp-verdin-wifi-canopus.dts ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/freescale
        install -m 0644 ${WORKDIR}/dts/canopus/imx8mp-verdin-canopus.dtsi ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/freescale
        install -m 0644 ${WORKDIR}/dts/canopus/imx8mp-verdin-wifi-canopus.dtsi ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/freescale

    else
        echo "installing ${MACHINE} dts..."
        install -m 0644 ${WORKDIR}/dts/yavia/imx8mp-verdin-yavia.dtsi ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/freescale

    fi
}

addtask patchextra after do_patch before do_compile

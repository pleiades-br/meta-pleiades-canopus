FILESEXTRAPATHS:prepend := "${THISDIR}/alsa-state/:"

# make this machine specific, as we have different codecs with different settings
PACKAGE_ARCH:tdx = "${MACHINE_ARCH}"

SRC_URI:append:mx8m-generic-bsp:tdx = " \
    file://plds-verdin-imx8mp-canopus/asound-canopus.conf \
    file://plds-verdin-imx8mp-canopus/asound-canopus.state \
    file://plds-verdin-imx8mp-canopus/asound-dev.conf \
    file://plds-verdin-imx8mp-canopus/asound-dev.state \
    file://plds-verdin-imx8mp-canopus/asound-dahlia.conf \
    file://plds-verdin-imx8mp-canopus/asound-dahlia.state \
"

FILES:${PN} += "${sysconfdir}/asound-*.conf"

do_install:append:mx8m-generic-bsp:tdx () {
    # Remove the default asound.conf, we need set up asound.conf dynamically
    # at runtime to support both dev/dahlia boards.
    rm -f ${D}${sysconfdir}/asound.conf
    rm -f ${D}${localstatedir}/lib/alsa/asound.state
    install -m 0644 ${WORKDIR}/plds-verdin-imx8mp-canopus/asound-*.conf ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/plds-verdin-imx8mp-canopus/asound-*.state ${D}${localstatedir}/lib/alsa
}

# Invalidate the default pkg_postinst in oe-core, this ensures our ontarget
# postinst to be the only one to run during package installation.
pkg_postinst:${PN}:mx8m-generic-bsp:tdx () {
}

pkg_postinst_ontarget:${PN}:mx8m-generic-bsp:tdx () {
    mv /etc/asound-dahlia.conf /etc/asound.conf
    mv /var/lib/alsa/asound-dahlia.state /var/lib/alsa/asound.state
    #rm -f /etc/asound-*.conf
    #rm -f /var/lib/alsa/asound-*.state
}
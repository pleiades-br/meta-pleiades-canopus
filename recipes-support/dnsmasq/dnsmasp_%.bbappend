FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://wifi-ap.conf \
    "

do_install:append() {
    install -d ${D}${sysconfdir}/dnsmasq.d
    install -m 0600 ${WORKDIR}//wifi-ap.conf ${D}${sysconfdir}/dnsmasq.d/
}
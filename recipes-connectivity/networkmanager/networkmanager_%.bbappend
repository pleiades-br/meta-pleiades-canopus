FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://lte-modem.nmconnection \
    file://NetworkManager.conf \    
    "

FILES:${PN} += " \
    ${sysconfdir}/NetworkManager/NetworkManager.conf \
    "

PACKAGECONFIG:append = " ppp modemmanager"

do_install:append() {
    install -d ${D}${sysconfdir}/NetworkManager/system-connections
    install -m 0600 ${WORKDIR}/lte-modem.nmconnection ${D}${sysconfdir}/NetworkManager/system-connections
    install -m 0644 ${WORKDIR}/NetworkManager.conf ${D}${sysconfdir}/NetworkManager
}

FILES_${PN} += " \
    ${nonarch_base_libdir}/NetworkManager/system-connections \
    ${nonarch_base_libdir}/NetworkManager \
"
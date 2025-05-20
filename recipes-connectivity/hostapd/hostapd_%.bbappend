FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://hostapd.conf \
    file://hostapd.service \
"

SYSTEMD_SERVICE:${PN} = "hostapd.service"

do_install:append() {
    install -m 0644 ${WORKDIR}/hostapd.conf  ${D}${sysconfdir}/


    install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/hostapd.service ${D}${systemd_system_unitdir}
    sed -i -e 's,@SBINDIR@,${sbindir},g' \
		-e 's,@SYSCONFDIR@,${sysconfdir},g' \
		-e 's,@BASE_BINDIR@,${base_bindir},g' \
		${D}${systemd_system_unitdir}/hostapd.service
}

FILES:${PN} += " ${systemd_system_unitdir}"
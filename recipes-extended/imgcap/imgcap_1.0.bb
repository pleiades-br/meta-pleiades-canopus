DESCRIPTION = "Wrapper for take raw images Video4Linux2 and converter to png"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=66a877f86cfc3ba8edd6ceeb2aadcef2"

SRC_URI = " \
    git://github.com/pleiades-br/canopus-imgcap.git;protocol=https;branch=main \
    "
SRCREV = "45ff9ad497cbe82d9f41a7834fa0c1ed1ef513e5"

S = "${WORKDIR}/git"

inherit setuptools3

do_install:append () {
    install -d ${D}${bindir}
    install -m 0755 imgcap ${D}${bindir}
}

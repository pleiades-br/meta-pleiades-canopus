FILESEXTRAPATHS:prepend := "${THISDIR}/imx219:${THISDIR}:"


#SRC_URI += "file://0001-isp-imx-add-imx219.patch" 
#SRC_URI += "file://0002-isp-imx-make-imx219-default.patch"
SRC_URI += " \
        file://imx219_isp-imx.patch \
        file://dewarp;subdir=extra \
        file://units;subdir=extra \
"

do_configure:prepend() {
    cp -r ${WORKDIR}/extra/dewarp ${S}/
    cp -r ${WORKDIR}/extra/units  ${S}/
}

#FILES_SOLIBS_VERSIONED += "${libdir}/libimx219.so"


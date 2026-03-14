FILESEXTRAPATHS:prepend := "${THISDIR}/imx219:${THISDIR}:"

SRC_URI += " \
    file://imx219_kernel-module-isp-vvcam.patch \
     file://v4l2;subdir=extra \    
"

do_configure:prepend() {
    cp -r ${WORKDIR}/extra/v4l2/sensor ${S}
}
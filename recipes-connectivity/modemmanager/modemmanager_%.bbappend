PACKAGECONFIG =  "vala mbim qmi at \
    ${@bb.utils.filter('DISTRO_FEATURES', 'systemd polkit', d)} \
"

PACKAGECONFIG[systemd] = " \
    -Dsystemdsystemunitdir=${systemd_unitdir}/system/, \
    -Dsystemdsystemunitdir=no -Dsystemd_journal=true -Dsystemd_suspend_resume=false \
"

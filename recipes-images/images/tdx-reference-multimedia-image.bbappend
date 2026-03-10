# Change the installation of some packages for canopus
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-client"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-gnome"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-plugin-wifi"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-plugin-ethernet"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-plugin-loopback"
# Add NetworkManager
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " networkmanager"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " modemmanager"
# Add i2c-tools
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " i2c-tools"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " udev-canopus-rules"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " km-eg91-ctrl"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " opencv"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " tensorflow-lite"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " keras"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " libcamera"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " hostapd"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " imagemagick imgcap"
#IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " aws-iot-device-client greengrass-lite"
#IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " openjdk-8"
#IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " sudo"

IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " hostapd-example"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " python3-wpa-supplicant wpa-supplicant"
IMAGE_FEATURES:remove:plds-verdin-imx8mp-canopus = "read-only-rootfs"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " wayland-qtdemo-launch-cinematicexperience"


IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " \
        x264 \
        gstreamer1.0-plugins-ugly \
"

PACKAGECONFIG:append_pn-gstreamer1.0-plugins-ugly = " x264"

IMAGE_CLASSES:append = " extrausers"

ROOT_DEFAULT_PASSWORD ?= "t00r@123"
DEFAULT_ADMIN_ACCOUNT ?= "admin"
DEFAULT_ADMIN_GROUP ?= "wheel sudo"
DEFAULT_ADMIN_ACCOUNT_PASSWORD ?= "admin"

LICENSE_FLAGS_ACCEPTED:append = " commercial"

IMAGE_LOGIN_MANAGER = "busybox shadow"
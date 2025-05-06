# Change the installation of some packages for canopus
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-client"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-gnome"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-plugin-wifi"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-plugin-ethernet"
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " connman-plugin-loopback"
# Add NetworkManager
IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " networkmanager"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " modemmanager"
# Add i2c-tools
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " i2c-tools"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " ruart"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " udev-canopus-rules"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " km-eg91-ctrl"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " opencv"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " tensorflow-lite"
IMAGE_INSTALL:append:plds-verdin-imx8mp-canopus = " keras"

IMAGE_INSTALL:remove:plds-verdin-imx8mp-canopus = " hostapd-example"

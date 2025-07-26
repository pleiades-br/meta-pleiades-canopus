# This class implements Toradex Easy Installer image type
# It allows to use OpenEmbedded to build images which can be consumed
# by the Toradex Easy Installer.
#
# Since it also generates the image.json description file it is rather
# interwind with the boot flow which is U-Boot target specific.

KERNEL_DEVICETREE_BASENAME = "${@make_dtb_boot_files(d)}"
WKS_FILE_DEPENDS:append = " tezi-metadata virtual/dtb"
DEPENDS += "${WKS_FILE_DEPENDS}"
IMAGE_BOOT_FILES_REMOVE = "${@'${KERNEL_DEVICETREE_BASENAME}' if d.getVar('KERNEL_IMAGETYPE') == 'fitImage' else ''}"
IMAGE_BOOT_FILES:append = " overlays.txt ${@'' if d.getVar('KERNEL_IMAGETYPE') == 'fitImage' else 'overlays/*;overlays/'}"
IMAGE_BOOT_FILES:remove = "${IMAGE_BOOT_FILES_REMOVE}"

RM_WORK_EXCLUDE += "${PN}"

# set defaults if not building with a Toradex distro
TDX_RELEASE ??= "0.0.0"
TDX_MATRIX_BUILD_TIME ??= "${DATETIME}"
TDX_MATRIX_BUILD_TIME[vardepsexclude] = "DATETIME"

EMMCDEV = "mmcblk0"
EMMCDEV:verdin-imx8mp = "emmc"
EMMCDEV:plds-verdin-imx8mp-canopus = "emmc"
EMMCDEVBOOT0 = "mmcblk0boot0"
EMMCDEVBOOT0:verdin-imx8mp = "emmc-boot0"
EMMCDEVBOOT0:plds-verdin-imx8mp-canopus = "emmc-boot0"
TEZI_VERSION ?= "${DISTRO_VERSION}"
TEZI_DATE ?= "${TDX_MATRIX_BUILD_TIME}"
TEZI_IMAGE_NAME ?= "${IMAGE_NAME}"
TEZI_ROOT_FSTYPE ??= "ext4"
TEZI_ROOT_FSOPTS ?= "-E nodiscard"
TEZI_ROOT_LABEL ??= "RFS"
TEZI_ROOT_NAME ??= "rootfs"
TEZI_ROOT_SUFFIX ??= "tar.xz"
TEZI_ROOT_PART_TYPE ??= "83"
TEZI_ROOT_PART_SIZE ??= "512"
TEZI_ROOT_FILELIST ??= ""
TEZI_DATA_ENABLED ??= "0"
TEZI_DATA_PART_SIZE ??= "512"
TEZI_DATA_PART_TYPE ??= "83"
TEZI_DATA_LABEL ??= "DATA"
TEZI_DATA_FSTYPE ??= "ext4"
TEZI_DATA_FSOPTS ?= "-E nodiscard"
TEZI_DATA_FILES ?= ""
TEZI_USE_BOOTFILES ??= "true"
TEZI_AUTO_INSTALL ??= "false"
TEZI_BOOT_SUFFIX ??= "${@'bootfs.tar.xz' if oe.types.boolean('${TEZI_USE_BOOTFILES}') else ''}"
TEZI_CONFIG_FORMAT ??= "2"
# Require newer Tezi for mx8 Socs with the u-boot environment bugfix
TEZI_CONFIG_FORMAT:mx8-generic-bsp ??= "4"
TORADEX_FLASH_TYPE ??= "emmc"
UBOOT_BINARY_TEZI_EMMC ?= "${UBOOT_BINARY}"
UBOOT_BINARY_TEZI_RAWNAND ?= "${UBOOT_BINARY}"
UBOOT_ENV_TEZI ?= "${@ 'u-boot-initial-env-%s' % d.getVar('UBOOT_CONFIG') if d.getVar('UBOOT_CONFIG') else 'u-boot-initial-env'}"
UBOOT_ENV_TEZI_EMMC ?= "${UBOOT_ENV_TEZI}"
UBOOT_ENV_TEZI_RAWNAND ?= "${UBOOT_ENV_TEZI}"

# use DISTRO_FLAVOUR to append to the image name displayed in TEZI
DISTRO_FLAVOUR ??= ""
SUMMARY:append = "${DISTRO_FLAVOUR}"

TEZI_EULA_FILE ?= "LA_OPT_NXP_SW.html"
TEZI_EULA_FILE:ti-soc ?= "TI-TFL.txt"
TEZI_EULA_URL ?= "https://www.nxp.com/docs/en/disclaimer/${TEZI_EULA_FILE}"
TEZI_EULA_URL:ti-soc ?= ""

# Append tar command to store uncompressed image size to ${T}.
# If a custom rootfs type is used make sure this file is created
# before compression.
IMAGE_CMD:tar:append = "; du -ks ${IMGDEPLOYDIR}/${IMAGE_NAME}.tar | cut -f 1 > ${T}/image-size${IMAGE_NAME_SUFFIX}"
CONVERSION_CMD:tar:append = "; du -ks ${IMGDEPLOYDIR}/${IMAGE_NAME}.${type}.tar | cut -f 1 > ${T}/image-size.${type}"
CONVERSION_CMD:tar = "touch ${IMGDEPLOYDIR}/${IMAGE_NAME}.${type}; ${IMAGE_CMD_TAR} --numeric-owner -cf ${IMGDEPLOYDIR}/${IMAGE_NAME}.${type}.tar -C ${TAR_IMAGE_ROOTFS} . || [ $? -eq 1 ]"
CONVERSIONTYPES:append = " tar"

def get_uncompressed_size(d, type):
    path = os.path.join(d.getVar('T'), "image-size.%s" % type)
    if not os.path.exists(path):
        return 0

    with open(path, "r") as f:
        size = f.read().strip()
    return float(size) / 1024

# Make an educated guess of the needed boot partition size
# max(16MB, 3x the size of the payload rounded up to the next 2^x number)
def get_bootfs_part_size(d):
    from math import log
    part_size = 3 * 2 ** (1 + int(log(get_uncompressed_size(d, 'bootfs'), 2)))
    return max(16, part_size)

def get_filelist_var(d, varname):
    filelist = d.getVar(varname)
    if not filelist:
        return None
    import re
    return re.split(r"\s+", filelist.strip())

def get_tezi_filelist_artifacts(d):
    filelist = get_filelist_var(d, 'TEZI_ROOT_FILELIST')
    if not filelist:
        return None
    artifacts = []
    for entry in filelist:
        artifacts.append(entry.split(":")[0])
    return artifacts

# Determine the storage space required for the given "filelist".
def get_filelist_extra_size(d, filelist):
    import shlex
    import subprocess

    extra_size = 0
    for entry in filelist:
        unpack = False
        flds = entry.split(":")
        fpath = os.path.join(d.getVar('IMGDEPLOYDIR'), flds[0])
        # Any non-empty string is considered as true except the strings "0" and
        # "false"; this is to be compatible with the QVariant used by Tezi.
        if len(flds) >= 3 and (flds[2] and flds[2].lower() not in ["0", "false"]):
            unpack = True
        if unpack and fpath.endswith(".zip"):
            # Deal with .zip files only:
            cmd = ("unzip -p %s | wc -c" % shlex.quote(fpath))
            bb.debug(1, "Running command [%s]" % cmd)
            outp = subprocess.check_output(cmd, shell=True)
            size = int(outp)
            bb.debug(1, "Unpacked size of '%s': %d (bytes)" % (fpath, size))
        elif unpack:
            # Deal with .tar.(gz|xz|bz2|lzo|zstd):
            cmd = ("tar -xf %s -O | wc -c" % shlex.quote(fpath))
            bb.debug(1, "Running command [%s]" % cmd)
            outp = subprocess.check_output(cmd, shell=True)
            size = int(outp)
            bb.debug(1, "Unpacked size of '%s': %d (bytes)" % (fpath, size))
        else:
            stat = os.stat(fpath)
            size = stat.st_size
            bb.debug(1, "Size of '%s': %d (bytes)" % (fpath, size))
        extra_size += size

    # Returned size is in MB.
    return float(extra_size) / 1024 / 1024

# Whitespace separated list of files declared by 'deploy_var' variable
# from 'source_dir' (DEPLOY_DIR_IMAGE by default) to place in 'deploy_dir'.
# Entries will be installed under a same name as the source file. To change
# the destination file name, pass a desired name after a semicolon
# (eg. u-boot.img;uboot). Exactly same rules with how IMAGE_BOOT_FILES being
# handled by wic.
def tezi_deploy_files(d, deploy_var, deploy_dir, source_dir=None):
    import os, re, glob, subprocess

    src_files = d.getVar(deploy_var) or ""
    src_dir = source_dir or d.getVar('DEPLOY_DIR_IMAGE')
    dst_dir = deploy_dir

    # list of tuples (src_name, dst_name)
    deploy_files = []
    for src_entry in re.findall(r'[\w;\-\./\*]+', src_files):
        if ';' in src_entry:
            dst_entry = tuple(src_entry.split(';'))
            if not dst_entry[0] or not dst_entry[1]:
                bb.fatal('Malformed file entry: %s' % src_entry)
        else:
            dst_entry = (src_entry, src_entry)
        deploy_files.append(dst_entry)

    # list of tuples (src_path, dst_path)
    install_task = []
    for deploy_entry in deploy_files:
        src, dst = deploy_entry
        if '*' in src:
            # by default install files under their basename
            entry_name_fn = os.path.basename
            if dst != src:
                # unless a target name was given, then treat name
                # as a directory and append a basename
                entry_name_fn = lambda name: \
                                os.path.join(dst,
                                             os.path.basename(name))

            srcs = glob.glob(os.path.join(src_dir, src))
            for entry in srcs:
                src = os.path.relpath(entry, src_dir)
                entry_dst_name = entry_name_fn(entry)
                install_task.append((src, entry_dst_name))
        else:
            install_task.append((src, dst))

    # install src_path to dst_path
    for task in install_task:
        src_path, dst_path = task
        install_cmd = "install -m 0644 -D %s %s" \
                      % (os.path.join(src_dir, src_path),
                         os.path.join(dst_dir, dst_path))
        try:
            subprocess.check_output(install_cmd, stderr=subprocess.STDOUT, shell=True)
        except subprocess.CalledProcessError as e:
            bb.fatal("Command '%s' returned %d:\n%s" % (e.cmd, e.returncode, e.output))

def rootfs_tezi_emmc(d, use_bootfiles):
    from collections import OrderedDict
    emmcdev = d.getVar('EMMCDEV')
    emmcdevboot0 = d.getVar('EMMCDEVBOOT0')
    imagename = d.getVar('IMAGE_LINK_NAME')
    offset_bootrom = d.getVar('OFFSET_BOOTROM_PAYLOAD')
    offset_fw = d.getVar('OFFSET_FW_PAYLOAD')
    offset_spl = d.getVar('OFFSET_SPL_PAYLOAD')

    bootpart_rawfiles = []
    filesystem_partitions = []

    offset_payload = offset_bootrom
    if offset_fw:
        # FIRMWARE_BINARY contain product_id <-> filename mapping
        fwmapping = d.getVarFlags('FIRMWARE_BINARY')
        for f, v in fwmapping.items():
            bootpart_rawfiles.append(
              {
                "filename": v,
                "dd_options": "seek=" + offset_payload,
                "product_ids": f
              })
        offset_payload = offset_fw
    if offset_spl:
        bootpart_rawfiles.append(
              {
                "filename": d.getVar('SPL_BINARY'),
                "dd_options": "seek=" + offset_payload
              })
        offset_payload = offset_spl
    bootpart_rawfiles.append(
              {
                "filename": d.getVar('UBOOT_BINARY_TEZI_EMMC'),
                "dd_options": "seek=" + offset_payload
              })

    if use_bootfiles:
        filesystem_partitions.append(
              {
                "partition_size_nominal": get_bootfs_part_size(d),
                "want_maximised": False,
                "content": {
                  "label": "BOOT",
                  "filesystem_type": "FAT",
                  "mkfs_options": "",
                  "filename": imagename + "." + d.getVar('TEZI_BOOT_SUFFIX'),
                  "uncompressed_size": get_uncompressed_size(d, 'bootfs')
                }
              })

    if d.getVar('TEZI_ROOT_FSTYPE') == "raw":
        rootfs = {
                   "partition_size_nominal": d.getVar('TEZI_ROOT_PART_SIZE'),
                   "partition_type": d.getVar('TEZI_ROOT_PART_TYPE'),
                   "want_maximised": True,
                   "content": {
                     "filesystem_type": "raw",
                     "rawfiles": [
                       {
                         "filename": imagename + "." + d.getVar('TEZI_ROOT_SUFFIX')
                       }
                     ],
                     "uncompressed_size": get_uncompressed_size(d, d.getVar('TEZI_ROOT_NAME'))
                   }
                 }
    else:
        rootfs = {
                   "partition_size_nominal": d.getVar('TEZI_ROOT_PART_SIZE'),
                   "want_maximised": True,
                   "content": {
                     "label": d.getVar('TEZI_ROOT_LABEL'),
                     "filesystem_type": d.getVar('TEZI_ROOT_FSTYPE'),
                     "mkfs_options": d.getVar('TEZI_ROOT_FSOPTS'),
                     "filename": imagename + "." + d.getVar('TEZI_ROOT_SUFFIX'),
                     "uncompressed_size": get_uncompressed_size(d, d.getVar('TEZI_ROOT_NAME'))
                   }
                 }

    rootfs_filelist = get_filelist_var(d, 'TEZI_ROOT_FILELIST')
    if rootfs_filelist:
        rootfs["content"]["filelist"] = rootfs_filelist
        rootfs["content"]["uncompressed_size"] += get_filelist_extra_size(d, rootfs_filelist)

    filesystem_partitions.append(rootfs)

    if d.getVar('TEZI_DATA_ENABLED') == "1":
        data = {
                   "partition_size_nominal": d.getVar('TEZI_DATA_PART_SIZE'),
                   "partition_type": d.getVar('TEZI_DATA_PART_TYPE'),
                   "want_maximised": True,
                   "content": {
                     "label": d.getVar('TEZI_DATA_LABEL'),
                     "filesystem_type": d.getVar('TEZI_DATA_FSTYPE'),
                     "mkfs_options": d.getVar('TEZI_DATA_FSOPTS'),
                     "filename": d.getVar('TEZI_DATA_FILES')
                   }
               }
        filesystem_partitions.append(data)

    return [
        OrderedDict({
          "name": emmcdev,
          "partitions": filesystem_partitions
        }),
        OrderedDict({
          "name": emmcdevboot0,
          "erase": True,
          "content": {
            "filesystem_type": "raw",
            "rawfiles": bootpart_rawfiles
          }
        })]


def rootfs_tezi_rawnand(d):
    from collections import OrderedDict
    imagename = d.getVar('IMAGE_LINK_NAME')

    uboot1 = OrderedDict({
               "name": "u-boot1",
               "content": {
                 "rawfile": {
                   "filename": d.getVar('UBOOT_BINARY_TEZI_RAWNAND'),
                   "size": 1
                 }
               },
             })

    uboot2 = OrderedDict({
               "name": "u-boot2",
               "content": {
                 "rawfile": {
                   "filename": d.getVar('UBOOT_BINARY_TEZI_RAWNAND'),
                   "size": 1
                 }
               }
             })

    env = OrderedDict({
        "name": "u-boot-env",
        "erase": True,
        "content": {}
    })

    rootfs = {
               "name": "rootfs",
               "content": {
                 "filesystem_type": "ubifs",
                 "filename": imagename + "." + d.getVar('TEZI_ROOT_SUFFIX'),
                 "uncompressed_size": get_uncompressed_size(d, d.getVar('TEZI_ROOT_NAME'))
               }
             }

    rootfs_filelist = get_filelist_var(d, 'TEZI_ROOT_FILELIST')
    if rootfs_filelist:
        rootfs["content"]["filelist"] = rootfs_filelist
        rootfs["content"]["uncompressed_size"] += get_filelist_extra_size(d, rootfs_filelist)

    kernel = {
               "name": "kernel",
               "size_kib": 12288,
               "type": "static",
               "content": {
                 "rawfile": {
                   "filename": d.getVar('KERNEL_IMAGETYPE'),
                   "size": 5
                 }
               }
             }

    # Use device tree mapping to create product id <-> device tree relationship
    dtmapping = d.getVarFlags('TORADEX_PRODUCT_IDS')
    dtfiles = []
    for f, v in dtmapping.items():
        dtfiles.append({ "filename": v, "product_ids": f })

    dtb = {
            "name": "dtb",
            "content": {
              "rawfiles": dtfiles
            },
            "size_kib": 128,
            "type": "static"
          }

    m4firmware = {
                   "name": "m4firmware",
                   "size_kib": 896,
                   "type": "static"
                 }

    ubi = OrderedDict({
            "name": "ubi",
            "ubivolumes": [kernel, dtb, m4firmware, rootfs]
          })

    return [uboot1, uboot2, env, ubi]

def rootfs_tezi_json(d, flash_type, flash_data, json_file, uenv_file):
    import json
    from collections import OrderedDict
    from datetime import datetime

    deploydir = d.getVar('DEPLOY_DIR_IMAGE')
    data = OrderedDict({ "config_format": d.getVar('TEZI_CONFIG_FORMAT'), "autoinstall": oe.types.boolean(d.getVar('TEZI_AUTO_INSTALL')) })

    # Use image recipes SUMMARY/DESCRIPTION...
    data["name"] = d.getVar('SUMMARY')
    data["description"] = d.getVar('DESCRIPTION')
    data["version"] = d.getVar('TEZI_VERSION')
    data["release_date"] = datetime.strptime(d.getVar('TEZI_DATE'), '%Y%m%d%H%M%S').date().isoformat()
    data["u_boot_env"] = uenv_file
    if os.path.exists(os.path.join(deploydir, "prepare.sh")):
        data["prepare_script"] = "prepare.sh"
    if os.path.exists(os.path.join(deploydir, "wrapup.sh")):
        data["wrapup_script"] = "wrapup.sh"
    if os.path.exists(os.path.join(deploydir, "marketing.tar")):
        data["marketing"] = "marketing.tar"
    if os.path.exists(os.path.join(deploydir, "toradexlinux.png")):
        data["icon"] = "toradexlinux.png"
    if d.getVar('TEZI_SHOW_EULA_LICENSE')  == "1":
        data["license"] = d.getVar('TEZI_EULA_FILE')

    product_ids = d.getVar('TORADEX_PRODUCT_IDS')
    if product_ids is None:
        bb.fatal("Supported Toradex product ids missing, assign TORADEX_PRODUCT_IDS with a list of product ids.")

    dtmapping = d.getVarFlags('TORADEX_PRODUCT_IDS')
    data["supported_product_ids"] = []

    # If no varflags are set, we assume all product ids supported with single image/U-Boot
    if dtmapping is not None:
        for f, v in dtmapping.items():
            dtbflashtypearr = v.split(',')
            if len(dtbflashtypearr) < 2 or dtbflashtypearr[1] == flash_type:
                data["supported_product_ids"].append(f)
    else:
        data["supported_product_ids"].extend(product_ids.split())

    if flash_type == "rawnand":
        data["mtddevs"] = flash_data
    elif flash_type == "emmc":
        data["blockdevs"] = flash_data

    with open(os.path.join(d.getVar('IMGDEPLOYDIR'), json_file), 'w') as outfile:
        json.dump(data, outfile, indent=4)
    bb.note("Toradex Easy Installer metadata file {0} written.".format(json_file))

def fw_binaries(d):
    fwmapping = d.getVarFlags('FIRMWARE_BINARY')

    if fwmapping is not None:
        fw_bins = []
        for key, val in fwmapping.items():
            if val not in fw_bins:
                fw_bins.append(val)
        return " " + " ".join(fw_bins)
    else:
        return ""

python rootfs_tezi_run_json() {
    artifacts = "%s/%s.%s" % (d.getVar('IMGDEPLOYDIR'), d.getVar('IMAGE_LINK_NAME'), d.getVar('TEZI_ROOT_SUFFIX'))
    flash_type = d.getVar('TORADEX_FLASH_TYPE')

    if len(flash_type.split()) > 1:
        bb.fatal("This class only supports a single flash type.")

    if flash_type == "rawnand":
        flash_data = rootfs_tezi_rawnand(d)
        uenv_file = d.getVar('UBOOT_ENV_TEZI_RAWNAND')
        uboot_file = d.getVar('UBOOT_BINARY_TEZI_RAWNAND')
        artifacts += " " + d.getVar('KERNEL_IMAGETYPE') + " " + d.getVar('KERNEL_DEVICETREE_BASENAME')
    elif flash_type == "emmc":
        use_bootfiles = oe.types.boolean(d.getVar('TEZI_USE_BOOTFILES'))
        flash_data = rootfs_tezi_emmc(d, use_bootfiles)
        uenv_file = d.getVar('UBOOT_ENV_TEZI_EMMC')
        uboot_file = d.getVar('UBOOT_BINARY_TEZI_EMMC')
        # TODO: Multi image/raw NAND with SPL currently not supported
        uboot_file += fw_binaries(d);
        uboot_file += " " + d.getVar('SPL_BINARY') if d.getVar('OFFSET_SPL_PAYLOAD') else ""
        artifacts += " " + "%s/%s.%s" % (d.getVar('IMGDEPLOYDIR'), d.getVar('IMAGE_LINK_NAME'), d.getVar('TEZI_BOOT_SUFFIX')) if use_bootfiles else ""
    else:
        bb.fatal("Toradex flash type unknown")

    artifacts += " " + uenv_file + " " + uboot_file
    artifacts_fl = get_tezi_filelist_artifacts(d)
    if artifacts_fl:
        for artifact in artifacts_fl:
            artifacts += " %s/%s" % (d.getVar('IMGDEPLOYDIR'), artifact)
    d.setVar("TEZI_ARTIFACTS", artifacts)

    rootfs_tezi_json(d, flash_type, flash_data, "image-%s.json" % d.getVar('IMAGE_BASENAME'), uenv_file)
}

python tezi_deploy_bootfs_files() {
    tezi_deploy_files(d, 'IMAGE_BOOT_FILES', os.path.join(d.getVar('WORKDIR'), 'bootfs'))
}
tezi_deploy_bootfs_files[dirs] =+ "${WORKDIR}/bootfs"
tezi_deploy_bootfs_files[cleandirs] += "${WORKDIR}/bootfs"
tezi_deploy_bootfs_files[vardeps] += "IMAGE_BOOT_FILES"

TAR_IMAGE_ROOTFS:task-image-bootfs = "${WORKDIR}/bootfs"
IMAGE_CMD:bootfs () {
       :
}
TEZI_IMAGE_BOOTFS_PREFUNCS ??= "tezi_deploy_bootfs_files"
do_image_bootfs[prefuncs] += "${TEZI_IMAGE_BOOTFS_PREFUNCS}"

TEZI_IMAGE_TEZIIMG_PREFUNCS ??= "rootfs_tezi_run_json"
IMAGE_TYPEDEP:teziimg += "${TEZI_BOOT_SUFFIX} ${TEZI_ROOT_SUFFIX}"
IMAGE_CMD:teziimg () {
	bbnote "Create Toradex Easy Installer tarball"

	# Copy image json file to ${WORKDIR}/image-json
	cp ${IMGDEPLOYDIR}/image-${IMAGE_BASENAME}.json ${WORKDIR}/image-json/image.json

	if [ -n "$TEZI_EULA_URL" ]; then
		curl -k --retry 5 -O ${TEZI_EULA_URL} || true
	fi

	local outfile stdoutfile
	outfile=${TEZI_IMAGE_NAME}-Tezi_${TEZI_VERSION}.tar
	stdoutfile=${TEZI_IMAGE_NAME}-Tezi.tar

	# The first transform strips all folders from the files to tar, the
	# second transform "moves" them in a subfolder ${TEZI_IMAGE_NAME}-Tezi_${TEZI_VERSION}.
	${IMAGE_CMD_TAR} \
		--transform='s/.*\///' \
		--transform 's,^,${TEZI_IMAGE_NAME}-Tezi_${TEZI_VERSION}/,' \
		-chf "${IMGDEPLOYDIR}/${outfile}" \
		toradexlinux.png marketing.tar prepare.sh wrapup.sh ${TEZI_EULA_FILE} \
		${WORKDIR}/image-json/image.json ${TEZI_ARTIFACTS}

	ln -sf "${outfile}" "${IMGDEPLOYDIR}/${stdoutfile}"
}
do_image_teziimg[dirs] += "${WORKDIR}/image-json ${DEPLOY_DIR_IMAGE}"
do_image_teziimg[cleandirs] += "${WORKDIR}/image-json"
do_image_teziimg[prefuncs] += "${TEZI_IMAGE_TEZIIMG_PREFUNCS}"
do_image_teziimg[recrdeptask] += "do_deploy"
do_image_teziimg[vardepsexclude] = "TEZI_VERSION TEZI_DATE"
do_image_teziimg[network] = "1"

#!/system/bin/sh

mkdir -p /firmware
mount | grep -q " /firmware " || mount -o bind /vendor/firmware_mnt /firmware 2>/dev/null

mkdir -p /vendor/firmware/wlan/qca_cld/kiwi_v2
cp /vendor/etc/wifi/kiwi_v2/WCNSS_qcom_cfg.ini   /vendor/firmware/wlan/qca_cld/kiwi_v2/WCNSS_qcom_cfg.ini 2>/dev/null

load_module() {
  name="$1"
  module_name="${name%.ko}"
  module_name="$(echo "$module_name" | tr '-' '_')"
  grep -q "^${module_name} " /proc/modules && return
  insmod "/vendor/lib/modules/$name" 2>/dev/null && return
  insmod "/vendor_dlkm/lib/modules/$name" 2>/dev/null && return
  insmod "/tmp/vendor/lib/modules/$name" 2>/dev/null && return
  insmod "/tmp/vendor_dlkm/lib/modules/$name" 2>/dev/null
}

load_module cfg80211.ko
load_module mac80211.ko
load_module wlan_firmware_service.ko
load_module cnss_prealloc.ko
load_module cnss_utils.ko
load_module cnss_nl.ko
load_module cnss_plat_ipc_qmi_svc.ko
load_module cnss2.ko
load_module icnss2.ko
load_module qca_cld3_kiwi_v2.ko

for fs in /sys/devices/platform/soc/*cnss*/fs_ready /sys/devices/platform/soc/*qcom,cnss*/fs_ready /sys/kernel/cnss/fs_ready; do
  [ -e "$fs" ] && echo 1 > "$fs" 2>/dev/null
 done

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  [ -e /sys/class/net/wlan0 ] && exit 0
  sleep 1
done
exit 1

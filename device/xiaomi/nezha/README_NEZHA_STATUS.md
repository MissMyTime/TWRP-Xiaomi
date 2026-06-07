# Xiaomi 17 Ultra / nezha TWRP Prototype

## Status

This is the eighteenth untested Xiaomi 17 Ultra (`nezha`) prototype derived from
the stable Redmi K90 Pro Max (`myron`) TWRP v35 base.

This revision deliberately returns to the v8 decryption chain. It keeps only
the independent MTP+ADB state-machine fix described below.

## Recovery Image Layout

- Separate recovery partition: `recovery_a` / `recovery_b`, 100 MiB each.
- Flash target: `recovery`, not `recovery_ab`.
- Android boot image header: v4.
- Kernel size inside `recovery.img`: `0`.
- The bootloader supplies the boot partition kernel at runtime. The image only
  contains the recovery ramdisk.

## Collected Device Values

- Device codename: `nezha`
- Model: Xiaomi 17 Ultra
- Platform: `canoe` / SM8850
- Display: `1200x2608`, density `480`
- Backlight: `/sys/class/backlight/panel0-backlight/brightness`
- Maximum brightness: `16383`
- CPU temperature: `/sys/class/thermal/thermal_zone78/temp`
- Touch input: `/dev/input/event8`
- Touch modules: `xiaomi_touch.ko`, `synaptics_tcm2.ko`
- Haptics input: `qcom-hv-haptics`
- WiFi module: `qca_cld3_peach_v2.ko`

The FBE metadata-encryption parameters in `recovery.fstab` were copied from the
system-side `/vendor/etc/fstab.qcom` collection.

## Goodix Weaver Fix In v2

The first prototype booted but could not decrypt user FBE credentials. Its
recovery log reached metadata decryption successfully, then failed while
querying Weaver key size. Phone-side properties confirmed that the stock system
uses:

```text
init.svc.goodix_weaver_hal_service=running
init.svc.secure_element_hal_service=running
init.svc.weaver_hal_service=stopped
```

The inherited NXP Weaver implementation has been removed. Prototype v2 imports
the stock `nezha` Goodix secure-element and Weaver services, their ODM
transport libraries, VINTF declaration and UBSan runtime. A recovery-side gate
starts the Goodix secure-element service first and waits for it to stabilize
before starting Goodix Weaver.

Prototype v2 logs showed that init refused to start the Goodix secure-element
binary because the stock rc file relies on a full-system SELinux domain
transition. Prototype v3 converts both Goodix init files into recovery-specific
services: the unusable `ro.special_edition` trigger is removed, the recovery
SELinux label is explicit, and the ODM library search path is supplied.

Prototype v3 diagnostics showed that the converted services are valid: a
manual late start registered `android.hardware.weaver.IWeaver/default`
successfully. Its automatic early start failed because mounting the real
vendor partition shadows the packaged `vendor/odm` directory and turns the
stock ODM path into an `/odm -> /vendor/odm -> /odm` symlink loop. Prototype
v4 duplicated the credential-unlock executables and their Goodix transport
libraries under stable rootfs `/sbin`, pointed the recovery init services
there, and retried Weaver startup a small number of times. Device testing
showed that the secure-element executable must retain its early ODM launch
path. Prototype v5 keeps the v3 secure-element path and moves only the later
Weaver launch to stable rootfs `/sbin`.

Prototype v5 device diagnostics showed that Android ramdisk copy rules
normalized the stable `/sbin` Weaver executable to mode `0644`. Both init and
a manual launch failed with `Permission denied`. A live `chmod 0755` followed
by `start goodix_weaver_hal_service` made the service remain `running`.
Prototype v6 restores the executable bit automatically before starting Weaver.

Prototype v6 hot diagnostics then reached the Goodix Weaver implementation,
but `Weaver::getConfig` still failed because `hlosminkdaemon` could not link
`libqmi_encdec.so`. Without the HLOS Mink opener, `libGPMTEEC_vendor.so` could
not open the TA session and reported `MAINTENANCE_ERROR_LOAD_TA`. Prototype v7
imports the missing QMI codec library and explicitly waits for
`vendor.minkdaemon` before starting the Goodix secure-element service.

Prototype v7 then kept all required services running and reported
`twrp.nezha.weaver_ready=1`, but password verification still failed while
opening the Goodix TA session. Logs showed that Mink could not load its stock
autoload configuration:

```text
library "libtaautoload.so" not found
Unable to open file /vendor/etc/ssg/ta_config.json
```

Prototype v8 imports the harvested `libtaautoload.so` and `/vendor/etc/ssg`
configuration directory. It also re-establishes the `/persist` bind mount
after module loading and before restarting QSEE, Mink and Goodix. The TA images
referenced by `ta_config.json` are supplied at runtime by the slot-aware modem
firmware mount at `/vendor/firmware_mnt`.

Prototype v8 device testing confirmed that FBE decryption works. USB logs then
showed that the handoff to MTP+ADB composite mode created `function0` and
`function1`, while init simultaneously recreated its expected `f1` and `f2`
links. Both paths raced to bind the same UDC and produced `File exists`,
`Invalid argument` and `Device or resource busy` errors. Prototype v9 keeps
the existing FFS MTP implementation but uses init-compatible configfs links:
ADB is always `f1`, and MTP is `f2` while composite mode is enabled.

Prototype v14 is branched from the v8 decryption behavior after later decrypt
experiments proved unreliable on real devices. Its USB switch waits until the
MTP FunctionFS endpoint is ready, then uses an internal `twrp_mtp_adb` state
while binding the `mtp+adb` composite gadget. This prevents init's adb-only
rule from racing the manual configfs handoff. If MTP is not ready or the UDC
bind fails, recovery restores adb-only mode instead of leaving USB offline.

Prototype v15 keeps the v8 decryption chain unchanged. Device testing confirmed
that v14 exposed both MTP and ADB FunctionFS endpoints successfully, but Windows
did not bind its Android ADB driver to Xiaomi's `2717:FF48` composite identity.
For `nezha`, v15 exposes the standard TWRP composite identity `18D1:4EE2`.
Disabling MTP now lets init restore adb-only mode first and applies the manual
configfs fallback only if the UDC remains unbound.

Prototype v16 keeps the v8 decryption chain unchanged. v15 diagnostics showed
that Windows could not read the composite gadget descriptor and that the DWC3
controller disconnected immediately after the handoff. The device init chain
also imported `/init.recovery.usb.rc` twice. v16 removes the duplicate import
and preserves the already-working ADB FunctionFS link as `f1`, appending MTP as
`f2` instead of rebuilding the composite gadget in the reverse order.

Prototype v17 keeps the v16 USB changes and hardens the Goodix credential
unlock startup. v16 field logs showed that Mink and QSEE remained available,
but the secure-element process could exit while Weaver was starting. Retrying
only Weaver then left `twrp.nezha.weaver_ready=0`. v17 restores the stock ODM
secure-element executable and vendor-first library order used by the earlier
stable chain. Each retry now restarts secure-element and Weaver as a pair and
accepts the chain only after both processes remain running.

Prototype v18 is aligned with a fresh official-system collection from
`OS3.0.306.0.WPACNXM`. Hash comparison confirmed that the imported Goodix,
Weaver, Mink, QSEE and SSG files already match the official system byte for
byte. The remaining runtime difference was service identity: the official
system runs QTI secure-element, Goodix secure-element and Goodix Weaver as
`system`, while the recovery overrides ran them as `root`. v18 restores the
stock service users and groups while retaining the recovery SELinux label,
library paths and v17 paired retry gate.

Prototype v19 keeps the verified v18 Goodix chain unchanged and narrows the
remaining change to USB composite enumeration. Field testing confirmed that
ADB works before MTP is enabled, but disappears during the experimental
`18D1:4EE2` composite handoff. v19 returns to the Xiaomi composite identity
`2717:FF48` and the ordering already used by the stable myron recovery:
MTP is `f1`, and ADB is `f2`.

Prototype v20 fixes intermittent credential decryption observed after a second
recovery boot. The failed boot log showed that TWRP partition probing could
leave `/odm` behind a symbolic-link loop. Init then rejected the Goodix eSE
service path with `Too many symbolic links encountered`, so Weaver never
started. v20 launches the packaged Goodix executable directly from the stable
`/vendor/odm/bin/hw` entity path and prefers `/vendor/odm/lib64` for its ODM
libraries. It also includes the v19 USB composite ordering change.

Useful first-test diagnostics:

```sh
adb shell getprop twrp.nezha.goodix_gate_started
adb shell getprop twrp.nezha.goodix_gate_error
adb shell getprop twrp.nezha.weaver_ready
adb shell getprop twrp.nezha.goodix_gate_attempt
adb shell getprop init.svc.secure_element_hal_service
adb shell getprop init.svc.goodix_weaver_hal_service
adb pull /tmp/recovery.log
```

## Important Test Warning

The collection was made on a rooted system reporting:

```text
ro.boot.flash.locked=1
ro.boot.vbmeta.device_state=locked
ro.boot.verifiedbootstate=green
```

This may be a fake-lock environment. Persistent third-party recovery boot can
still be rejected by the AVB or ABL chain even when flashing succeeds.

For the first test:

1. Keep the matching stock `recovery.img` ready.
2. Prefer a genuinely unlocked test device or a known-safe restore route.
3. Flash with `fastboot flash recovery recovery.img`.
4. Reboot directly to recovery before attempting a normal system boot.
5. Validate UI, touch, ADB, MTP, vibration and WiFi before testing decryption.
6. Test decryption only after the basic recovery functions are confirmed.

## Build Notes

Imported phone-side files are normalized with readable permissions before
building. Android 16 ramdisk `/odm/*` paths are symlinks into `/vendor/odm/*`,
so real ODM files are packaged under `recovery/root/vendor/odm`.

The bundled vendor kernel modules report the collected Xiaomi kernel ABI:

```text
6.12.23-android16-5-g0cd5a311d2f7-mi-4k
```

The placeholder `prebuilt/kernel` file remains present only because the Android
build rules expect one. It is excluded from the generated recovery image.

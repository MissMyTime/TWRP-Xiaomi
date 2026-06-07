#!/usr/bin/env python3
"""Apply TWRP 16 reboot patches for nezha device."""
import sys

FILE = '/root/twrp16/bootable/recovery/twrp-functions.cpp'

with open(FILE, 'r') as f:
    text = f.read()

changes = 0

# Patch 1: Clear BCB before switch
old1 = '\t}\n\n\tswitch (command) {'
new1 = '\t}\n\n\t// Clear BCB before any reboot to prevent bootloop back to recovery\n\tClear_Bootloader_Message();\n\n\tswitch (command) {'
if old1 in text:
    text = text.replace(old1, new1, 1)
    changes += 1
    print('OK: Clear_Bootloader_Message() added before switch')

# Patch 2: rb_fastboot → bootloader
old2 = '\t\tcase rb_fastboot:\n\t\t\treturn property_set(ANDROID_RB_PROPERTY, "reboot,fastboot");'
new2 = '\t\tcase rb_fastboot:\n\t\t\tClear_Bootloader_Message();\n\t\t\treturn property_set(ANDROID_RB_PROPERTY, "reboot,bootloader");'
if old2 in text:
    text = text.replace(old2, new2)
    changes += 1
    print('OK: rb_fastboot now uses bootloader + BCB clear')

if changes == 0:
    print('WARNING: No patches applied! Check source file.')
    sys.exit(1)

with open(FILE, 'w') as f:
    f.write(text)
print(f'Done: {changes}/2 patches applied')

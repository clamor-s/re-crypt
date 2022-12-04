# re-crypt
A tool for re-partitioning Tegra 2 and Tegra 3 based product devices.

re-crypt is a small tool which allows to replace vendor designed TegraPT with more generic one which works better with U-Boot and Linux overall. 

## Problems of Tegra 2/3/4 product devices:
- use of custom TegraPT which is not widely supported and conflicts with default setups
- use of proprietary bootloader which was not updated for a decade
- use of AES encryption for BCT (boot configuration table) and EBT (bootloader)

Last one is not a problem but rather an unfortunate measure which makes devs life harder.

## Solutions
- perform a re-partiton to match default setup and primary partitions of TegraPT, this will allow to use all mmcblk0 block as GPT storage without risk of breaking bootloader
- switch to open source bootloader U-Boot which still has quite strong Tegra support
- store AES encryption key in BCT region to be able to update bootloader without host PC (not ideal but tegra SE is not documented to be properly implemented)

## Implementation
re-crypt script performs bootloader encryption, bct patching and encryption as well as packing them into primary 4MB block. Then this block can be flashed via nvflash or fusee gelee.

## Credits
[CrackTheSurface](https://github.com/CrackTheSurface) for [firmware cryptography](https://openrt.gitbook.io/open-surfacert/surface-rt/firmware/encrypt-firmware)

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

## Usage
You need to have a u-boot for your device built pre-emptively. Clone this repo, place your u-boot inside it (same level as re-crypt script).
re-crypt script supports 3 keys:
- `-k` to define SBK of your device (optional)
- `-b` to set name of your bootloader (optional, default name is `u-boot-dtb-tegra.bin`)
- `-d` to pass device name (mandatory)

### List of supported devices
| Device  | Codename | Note |
| - | - | - |
| ASUS Eee Pad Transformer TF101 | tf101v1 | Only for SBK 1 version, no need in `-k` |
| ASUS Eee Pad Transformer TF101 | tf101v2 |  |
| ASUS Transformer Prime TF201 | tf201 | Requires SBK |
| ASUS Transformer Pad TF300T | tf300t | Requires SBK |
| ASUS Transformer Pad 3G TF300TG | tf300tg | Requires SBK |
| ASUS VivoTab RT TF600T | tf600t | Requires SBK |
| ASUS Transformer Infinity TF700T | tf700t | Requires SBK |
| ASUS Transformer AiO P1801-T | p1801-t | Requires SBK |
| LG Optimus 4X HD | p880 | No need in `-k` |
| LG Optimus Vu | p895 | No need in `-k` |
| ASUS/Google Nexus 7 (2012) | grouper | Requires SBK |
| Pegatron Chagall | chagall | Requires SBK |
| HTC One X | endeavoru | No need in `-k` |

Example of command call for ASUS Transformer Prime TF201

`./re-crypt.sh -d tf201 -k deadbeefdeadc0dedeadd00dfee1dead -b u-boot.bin`

## Credits
[CrackTheSurface](https://github.com/CrackTheSurface) for [firmware cryptography](https://openrt.gitbook.io/open-surfacert/surface-rt/firmware/encrypt-firmware)

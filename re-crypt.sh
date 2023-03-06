#!/bin/bash
echo "Build FlashImage from BCT/Bootloader"

ENDEAVORU=588f67e66c763ff94a74b97924b3a499
P880=c18269ee0900ce58482abe34bff1bc01
P895=950821ad0964ce58fe98be34bff1ac02
TF101v1=1682ccd88a1a43eaa532eeb6ecfe1d98 

while getopts ":d:k:b:h" option; do
    case "${option}" in
        k)
            key=${OPTARG}
            ;;
        b)
            Bootloader=${OPTARG}
            ;;
        d)
            BCT=${OPTARG}.bct
            case "${OPTARG}" in
                tf101v1)
                    BCT=tf101.bct
                    key=$TF101v1
                    ;;
                tf101v2)
                    BCT=tf101.bct
                    ;;
                p880)
                    key=$P880
                    ;;
                p895)
                    key=$P895
                    ;;
                endeavoru)
                    key=$ENDEAVORU
                    ;;
            esac
            ;;
        h)
            echo "re-crypt supports next keys"
            echo "-d to specify device"
            echo "-k to specify SBK"
            echo "-b to specify bootloader name"
            exit 2
            ;;
    esac
done

if [ "$BCT" = "" ]; then
    echo "No device found! Use -d to specify the device."
    exit 3
fi

case "$BCT" in
    tf101.bct)
        HashEntry=2736
        LengthEntry=2720
	BctSize=2
	SBKEntry=4080
        ;;
    tf201.bct | tf300t.bct | tf300tg.bct | tf600t.bct | tf700t.bct | p1801-t.bct | p880.bct | p895.bct | grouper.bct | chagall.bct | endeavoru.bct)
        HashEntry=3952
        LengthEntry=3936
	BctSize=3
	SBKEntry=6128
        ;;
    *)
        echo "Device is not supported! Check README to get list of supported devices."
        exit 4
        ;;
esac

if [ "$key" = "" ]; then
    echo "SBK is not found! Use -k to specify your SBK."
    exit 3
fi

if [ "$Bootloader" = "" ]; then
    Bootloader=u-boot-dtb-tegra.bin
fi

cp bct/$BCT tmp_bct.bin
cp $Bootloader tmp_bootloader.bin

###############################################################################
########### BOOTLOADER ########################################################
###############################################################################

# pad bootloader to be 16 Byte aligned
bootloaderLength=$(stat --printf="%s" tmp_bootloader.bin)
while [ $((bootloaderLength%16)) -ne 0 ]; do
	echo -n -e \\x00 >> tmp_bootloader.bin
	bootloaderLength=$(stat --printf="%s" tmp_bootloader.bin)
done

# encrypt bootloader
openssl aes-128-cbc -e -K $key -iv 00000000000000000000000000000000 -nopad -nosalt -in tmp_bootloader.bin -out tmp_bootloader_enc.bin #-nopad

# calc bootloader hash of encrypted bootloader
bootloaderHash=$(openssl dgst -mac cmac -macopt cipher:aes-128-cbc -macopt hexkey:$key tmp_bootloader_enc.bin | cut -d' ' -f2)
# get length of encrypted bootloader
bootloaderLength=$(stat --printf="%s" tmp_bootloader_enc.bin)

# Swap endianess of Length
v=$(printf "%08x" $bootloaderLength)
bootloaderLength=${v:6:2}${v:4:2}${v:2:2}${v:0:2}

# add bootloader data to BCT
echo $bootloaderHash	| xxd -r -p | dd conv=notrunc of=tmp_bct.bin seek=$HashEntry bs=1
echo $bootloaderLength 	| xxd -r -p | dd conv=notrunc of=tmp_bct.bin seek=$LengthEntry bs=1

###############################################################################
########### BCT ###############################################################
###############################################################################
# remove HASH from BCT
dd if=tmp_bct.bin of=tmp_bct_trimmed.bin bs=1 skip=16

# encrypt BCT
openssl aes-128-cbc -e -K $key -iv 00000000000000000000000000000000 -nopad -nosalt -in tmp_bct_trimmed.bin -out tmp_bct_trimmed_enc.bin

# hash encrypted BCT
BCT_hash=$(openssl dgst -mac cmac -macopt cipher:aes-128-cbc -macopt hexkey:$key tmp_bct_trimmed_enc.bin | cut -d' ' -f2)

# create BCT_block image
dd if=/dev/zero of=tmp_bct_block.bin bs=2048 count=$BctSize
# put hash in Image
echo $BCT_hash 		| xxd -r -p | dd conv=notrunc of=tmp_bct_block.bin seek=0 bs=1
# put BCT in Image
dd conv=notrunc if=tmp_bct_trimmed_enc.bin of=tmp_bct_block.bin seek=16 bs=1
# append SBK to BCT
echo $key 		| xxd -r -p | dd conv=notrunc of=tmp_bct_block.bin seek=$SBKEntry bs=1

cp tmp_bct_block.bin tmp_bct_enc.bin

###############################################################################
########### BLOCK #############################################################
###############################################################################
#create zero bricksave image
dd if=/dev/zero of=repart-block.bin bs=2048 count=2048

dd conv=notrunc if=tmp_bct_enc.bin of=repart-block.bin seek=0 bs=1
dd conv=notrunc if=tmp_bootloader_enc.bin of=repart-block.bin seek=2097152 bs=1

###############################################################################
########### Remove Tmp files ##################################################
###############################################################################
rm tmp_*.bin

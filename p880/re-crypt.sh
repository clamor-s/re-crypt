#!/bin/bash
echo "Build FlashImage from BCT/Bootloader"

# Change these 3 variables
BCT=p880.bct
Bootloader=u-boot-dtb-tegra.bin
key=c18269ee0900ce58482abe34bff1bc01

cp $BCT tmp_bct.bin
cp $Bootloader tmp_bootloader.bin
###############################################################################
########### BOOTLOADER ########################################################
###############################################################################

#pad bootloader to be 16Byte aligned
bootloaderLength=$(stat --printf="%s" tmp_bootloader.bin)
while [ $((bootloaderLength%16)) -ne 0 ]; do
	echo -n -e \\x00 >> tmp_bootloader.bin
	bootloaderLength=$(stat --printf="%s" tmp_bootloader.bin)
done

# encrypt bootloader
echo "test"
openssl aes-128-cbc -e -K $key -iv 00000000000000000000000000000000 -nopad -nosalt -in tmp_bootloader.bin -out tmp_bootloader_enc.bin #-nopad
echo "test"

# calc bootloader hash of encrypted bootloader
bootloaderHash=$(openssl dgst -mac cmac -macopt cipher:aes-128-cbc -macopt hexkey:$key tmp_bootloader_enc.bin | cut -d' ' -f2)
# get length of encrypted bootloader
bootloaderLength=$(stat --printf="%s" tmp_bootloader_enc.bin)

# Swap endianess of Length
v=$(printf "%08x" $bootloaderLength)
bootloaderLength=${v:6:2}${v:4:2}${v:2:2}${v:0:2}

# add bootloader data to BCT
echo $bootloaderHash	| xxd -r -p | dd conv=notrunc of=tmp_bct.bin seek=3952 bs=1
echo $bootloaderLength 	| xxd -r -p | dd conv=notrunc of=tmp_bct.bin seek=3936 bs=1

# export encrypted bootloader
cp tmp_bootloader_enc.bin bootloader_enc.bin

###############################################################################
########### BCT ###############################################################
###############################################################################
# remove HASH from BCT
dd if=tmp_bct.bin of=tmp_bct_trimmed.bin bs=1 skip=16

# encrypt BCT
openssl aes-128-cbc -e -K $key -iv 00000000000000000000000000000000 -nopad -nosalt -in tmp_bct_trimmed.bin -out tmp_bct_trimmed_enc.bin

# hash encrypted BCT
BCT_hash=$(openssl dgst -mac cmac -macopt cipher:aes-128-cbc -macopt hexkey:$key tmp_bct_trimmed_enc.bin | cut -d' ' -f2)

#create BCT_block image
dd if=/dev/zero of=tmp_bct_block.bin bs=1 count=6144
#put hash in Image
echo $BCT_hash 		| xxd -r -p | dd conv=notrunc of=tmp_bct_block.bin seek=0 bs=1
#put BCT in Image
dd conv=notrunc if=tmp_bct_trimmed_enc.bin of=tmp_bct_block.bin seek=16 bs=1
#append SBK to BCT
echo $key 		| xxd -r -p | dd conv=notrunc of=tmp_bct_block.bin seek=6128 bs=1

cp tmp_bct_block.bin bct_enc.bin

###############################################################################
########### BLOCK #############################################################
###############################################################################
#create zero bricksave image
dd if=/dev/zero of=repart-block.bin bs=1 count=4194304

dd conv=notrunc if=bct_enc.bin of=repart-block.bin seek=0 bs=1
dd conv=notrunc if=bootloader_enc.bin of=repart-block.bin seek=2097152 bs=1

###############################################################################
########### Remove Tmp files ##################################################
###############################################################################
rm tmp_*.bin
rm bct_enc.bin
rm bootloader_enc.bin

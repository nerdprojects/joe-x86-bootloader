# Joe Bootloader
This is a x86 bootloader I created to play around with x86 assembly, BIOS and real mode.
It does not really bootload anything, instead it displays an animation of a pixel character named Joe.
<img src="https://raw.githubusercontent.com/nerdprojects/joe-x86-bootloader/main/joe-x86-bootloader.png"/>

You can compile it with nasm:

    nasm joe.asm

You can build a bootable floppy out of it and run it on a virtual machine:

    nasm joe.asm
    dd if=/dev/zero of=floppy.img bs=1024 count=1440
    printf '\x55\xAA' | dd of=floppy.img bs=1 seek=510 count=2 conv=notrunc
    dd if=joe of=floppy.img conv=notrunc

Or you can prank someone, by overwriting the boot sector on his harddrive ;-).
But I guess this will only work with MBR disks and not with UEFI:

    dd if=/dev/sda of=backup.bin count=278 bs=1
    dd of=/dev/sda if=joe count=278 bs=1 conv=notrunc

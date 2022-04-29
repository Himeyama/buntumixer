```bash
sudo qemu-system-x86_64 \
    -hda ~/hikarilinux-22.04.qcow2 \
    -m 4G \
    -cdrom mylinux.iso \
    -boot d \
    --enable-kvm \
    -usb \
    -smp 6
```
ISO イメージの展開を行います。
作業ディレクトリーに以下のディレクトリーが作成されます。

- mnt (Live CD をマウントしたもの)
- extract-dir (Live CD のコピー)
- squashfs (extract-dir/casper/filesystem.squashfs をマウントしたもの)
- root (squashfs のコピー)

以下のディレクトリーは /dev をバインドマウントしています。
- root/dev

```bash
sudo $(which bundle) exec buntumixer prep -s ubuntu-22.04-desktop-amd64.iso
```

`sudo chroot root` でイメージをカスタマイズします。

```bash
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
```

```bash
echo nameserver 1.1.1.1 | tee /etc/resolv.conf
```

例えば、LibreOffice を消したい場合は、以下を実行します。
```bash
apt update
libreoffices=$(apt list libreoffice-* 2>/dev/null | sed -E 's/\/.*?$//g' | tail -n +2)
apt purge $libreoffices -y
apt autoremove -y
```

を実行し名前解決可能にします。

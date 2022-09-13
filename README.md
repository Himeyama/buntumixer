# buntumixer
[![Ruby](https://github.com/Himeyama/buntumixer-dev/actions/workflows/main.yml/badge.svg)](https://github.com/Himeyama/buntumixer-dev/actions/workflows/main.yml)

## 概要
Ubuntu の LiveCD をカスタマイズするツール。

## 動作環境
- Windows 11 (WSL2)
- Ubuntu

## 依存パッケージのインストール
```bash
sudo add-apt-repository ppa:ubuntu-foundations-team/cd-boot-images
sudo apt update
sudo apt install -y squashfs-tools xorriso cd-boot-images-amd64
```

上記のパッケージがインストールされているかを必ず確認してください。

## インストール
```bash
gem install buntumixer
```

## コマンド
### コマンドのヘルプを表示
```bash
# ヘルプを表示
bundle exec buntumixer

# 使用法を表示
bundle exec buntumixer using
```

### ISO イメージを展開し作業ディレクトリーを準備

> 例

```bash
sudo $(which bundle) exec buntumixer prepare -s ubuntu-22.04-desktop-amd64.iso -v 22.04 -n "Customized Linux"
```

### スクリプトの適用
Ubuntu をカスタマイズするためのスクリプトを指定し、展開された OS イメージに対して実行します。

ディレクトリー直下に `root` が存在する場合は、`-d root` を指定します。

```bash
sudo $(which bundle) exec buntumixer apply -s CustomizedLinux.sh -d root
```

### ISO 化
作業ディレクトリーをもとに ISO ファイルを生成します。

```bash
sudo $(which bundle) exec buntumixer create -o CustomizedLinux.iso
```

### 作業ディレクトリの後片付け

`buntumixer prepare` で生成された作業ディレクトリーに対しアンマウント及び削除を行います。

生成された ISO ファイルや元の ISO ファイルは**削除されません**。

このコマンドは、作業ディレクトリー内で実行する必要があります。

```bash
sudo $(which bundle) exec buntumixer clear
```

#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "log"

# LiveCD をカスタマイズ
class CustomLiveCD
  def initialize
    @mount_point = "mnt"
    @squashfs = "squashfs"
    @extract_dir = "extract-dir"
    @root_dir = "root"
    @release_notes_url = ""
    @distribution_name = "Customised Ubuntu"
    @distribution_version = "22.04"
  end

  def clear
    root?

    umount("#{@root_dir}/dev")
    rm_dir(@root_dir)
    umount(@squashfs)
    rm_dir(@squashfs)
    rm_dir(@extract_dir)
    umount(@mount_point)
    rm_dir(@mount_point)
  end

  def root?
    return if Process::UID.eid.zero?

    Log.error("root 権限で実行する必要があります")
    exit false
  end

  def prep
    root?

    if @src_iso.nil?
      Log.error("ISO ファイルが指定されていません。")
      exit false
    end

    unless File.exist?(@src_iso)
      Log.error("ISO ファイル (#{@src_iso}) が存在しません")
      exit false
    end

    clear

    Log.info("ISO ファイル (#{@src_iso}) のマウントを行っています...")
    FileUtils.mkdir_p(@mount_point)
    if system("mountpoint -q #{@mount_point}")
      Log.info("既にマウントしています。")
    else
      Log.error("マウントに失敗しました。") unless system("mount -o loop #{@src_iso} #{@mount_point}")
    end

    Log.info("ISO イメージ内のディレクトリーをコピーしています...")
    FileUtils.mkdir_p(@extract_dir)
    unless system("rsync -a --exclude=/casper/filesystem.squashfs #{@mount_point}/ #{@extract_dir}/")
      Log.error("#{@mount_point} から #{@extract_dir} へのコピーが失敗しました。")
    end
    Log.info("#{@extract_dir} にあるファイルのパーミッションを変更しています...")
    FileUtils.chmod_R("+rw", @extract_dir)

    Log.info("システムイメージ (#{@mount_point}/casper/filesystem.squashfs) を #{@squashfs} へ展開しています...")
    FileUtils.mkdir_p(@squashfs)
    if system("mountpoint -q #{@squashfs}")
      Log.info("既にマウントしています。")
    else
      unless system("mount -t squashfs -o loop #{@mount_point}/casper/filesystem.squashfs #{@squashfs}")
        Log.error("マウントに失敗しました。")
      end
    end

    Log.info("#{@squashfs} を #{@root_dir} へのコピーしています...")
    FileUtils.mkdir_p(@root_dir)
    Log.error("#{@squashfs} から #{@root_dir} へのコピーに失敗しました。") unless system("cp -a #{@squashfs}/* #{@root_dir}")

    Log.info("リリースノートを設定しています...")
    File.open("#{@extract_dir}/.disk/release_notes_url", "w") do |f|
      f.print(@release_notes_url)
    end

    Log.info("ディスク情報を設定しています...")
    File.open("#{@extract_dir}/.disk/info", "w") do |f|
      today = Time.new.strftime("%Y%m%d")
      f.print("#{@distribution_name} #{@distribution_version} - Release amd64 (#{today})")
    end

    # ここをメソッド化
    Log.info("言語設定をしています...")
    File.open("#{@extract_dir}/preseed/ubuntu.seed", "a") do |f|
      f.print <<~SEED
        d-i	debian-installer/language	string	ja
        d-i	debian-installer/locale	string	ja_JP.UTF-8
        d-i	keyboard-configuration/layoutcode	string	jp
        d-i	keyboard-configuration/modelcode	string	pc105
      SEED
    end

    set_grub_cfg
    min_rm_add

    Log.info("バインドマウントをしています (/dev)...")
    if system("mountpoint -q #{@root_dir}/dev")
      Log.info("既にマウントしています。")
    else
      unless system("mount -B /dev/ #{@root_dir}/dev")
        Log.error("マウントできません。")
        exit
      end
    end

    Log.info("一連の処理が完了しました。#{@root_dir} を編集してください。")
  end

  attr_writer(
    :src_iso,
    :dst_iso,
    :extract_dir,
    :mount_point,
    :squashfs,
    :root_dir,
    :release_notes_url,
    :distribution_name,
    :distribution_version
  )

  private

  def rm_dir(dir)
    return if dir.nil?

    return unless Dir.exist?(dir)

    Log.info("#{dir} を削除しています...")
    FileUtils.rm_rf(dir)
  end

  def min_rm_add
    file = "#{@extract_dir}/casper/filesystem.manifest-minimal-remove"
    min_rm = File.open(file).read
    min_rm.gsub!(/.*?mozc.*?\n/, "")
    min_rm.gsub!(/.*?japanese.*?\n/, "")
    min_rm += 'ubuntu-ja-live-fix\n'

    File.open(file, "w") do |f|
      f.print min_rm
    end
  end

  def set_grub_cfg
    file = "#{@extract_dir}/boot/grub/grub.cfg"
    grub_cfg = File.open(file).read
    return if grub_cfg.match("ja_JP")

    Log.info("#{file} を日本語に設定しています...")
    splash = "splash --- " \
             "debian-installer/language=ja " \
             "debian-installer/locale=ja_JP.UTF-8 " \
             "keyboard-configuration/layoutcode?=jp " \
             "keyboard-configuration/modelcode?=pc105"
    File.open(file, "w") do |f|
      f.print grub_cfg.gsub("splash ---", splash)
    end
  end

  def umount(dir)
    if Dir.exist?(dir) && system("mountpoint -q #{dir}")
      Log.info("マウントを解除しています (#{dir})...")
      Log.error("マウントの解除に失敗しました。") unless system("umount #{dir}")
    end
  end
end

if $PROGRAM_NAME == __FILE__
  # my_linux = CustomLiveCD.new
  # my_linux.src_iso = '/mnt/d/ubuntu-22.04-desktop-amd64.iso'
  # my_linux.dst_iso = 'hikarilinux-22.04-desktop-amd64.iso'
  # # my_linux.prep
  # my_linux.clean
end

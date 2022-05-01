#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "log"
require "digest"

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
    @volume_id = "Customised Linux 22.04"
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
      Log.error("マウントに失敗しました。") unless system("mount -o loop #{@src_iso} #{@mount_point} 2>/dev/null")
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

  def create
    root?

    unless Dir.exist?(@extract_dir)
      Log.error("#{@extract_dir} は存在しません。")
      exit false
    end

    unless Dir.exist?(@mount_point)
      Log.error("#{@mount_point} は存在しません。")
      exit false
    end

    if @dst_iso.nil?
      Log.error("ISO の出力先が指定されていません。")
      exit false
    end

    # filesystem.manifest の作成
    Log.info("#{@extract_dir}/casper/filesystem.manifest に書き込んでいます...")
    show_format = "--showformat='${binary:Package}\t${Version}\n'"
    filesystem_manifest = `chroot #{@root_dir}/ dpkg-query -W #{show_format}`
    File.open("#{@extract_dir}/casper/filesystem.manifest", "w") do |f|
      f.puts filesystem_manifest
    end
    fs_manifest = File.open("#{@mount_point}/casper/filesystem.manifest").read
    File.open("#{@extract_dir}/casper/filesystem.manifest", "w") do |f|
      f.puts fs_manifest.lines.map { |line|
        line =~ /^(snap:.*?)$/
        Regexp.last_match(1)
      }.compact.join("\n")
    end

    Log.info("不要なファイルを削除しています...")
    FileUtils.rm_rf("#{@root_dir}/root/.bash_history")
    FileUtils.rm_rf("#{@root_dir}/tmp/*")
    FileUtils.rm_rf("#{@root_dir}/var/lib/apt/lists/*")
    FileUtils.rm_rf("#{@root_dir}/var/cache/debconf/*-old")
    umount("#{@root_dir}/dev/")

    Log.info("#{@extract_dir}/casper/filesystem.size を作成しています...")
    fs_size = `du -B 1 -s #{@root_dir}/ | cut -f1`
    File.open("#{@extract_dir}/casper/filesystem.size", "w") do |f|
      f.print fs_size
    end

    fs_squashfs_file = "#{@extract_dir}/casper/filesystem.squashfs"
    if File.exist?(fs_squashfs_file)
      Log.info("古いファイル (#{fs_squashfs_file}) が存在するため、削除しています...")
      FileUtils.rm_rf(fs_squashfs_file)
    end
    Log.info("#{fs_squashfs_file} を作成しています...")
    unless system("mksquashfs #{@root_dir}/ #{fs_squashfs_file} -xattrs -comp xz")
      Log.error("filesystem.squashfs の作成に失敗しました。")
      exit false
    end

    Log.info("#{@extract_dir}/boot.catalog を削除しています...")
    FileUtils.rm_rf("#{@extract_dir}/boot.catalog")

    Log.info("md5sum.txt を作成しています...")
    md5sum = Dir.glob("#{@extract_dir}/**/*").map do |file|
      md5 = Digest::MD5.file(file).hexdigest if File.file?(file)
      file =~ %r{^.*?(/.*)$}
      rfile = Regexp.last_match(1)
      output = "#{md5}  .#{rfile}" if File.file?(file)
      output = nil if rfile.match(%r{^/EFI})
      output = nil if rfile.match(%r{^/boot})
      output = nil if rfile == "/md5sum.txt"
      output
    end.compact
    File.open("#{@extract_dir}/md5sum.txt", "w") do |f|
      f.puts md5sum
      f.puts "#{Digest::MD5.file("#{@extract_dir}/boot/memtest86+.bin").hexdigest}  ./boot/memtest86+.bin"
      f.puts "#{Digest::MD5.file("#{@extract_dir}/boot/grub/grub.cfg").hexdigest}  ./boot/grub/grub.cfg"
      f.puts "#{Digest::MD5.file("#{@extract_dir}/boot/grub/loopback.cfg").hexdigest}  ./boot/grub/loopback.cfg"
    end

    Log.info("ISO を作成しています...")
    xorriso_cmd = "xorriso " \
      "-as mkisofs " \
      "-volid \"#{@volume_id}\" " \
      "-o #{@dst_iso} " \
      "-J -joliet-long -l " \
      "-b boot/grub/i386-pc/eltorito.img " \
      "-no-emul-boot " \
      "-boot-load-size 4 " \
      "-boot-info-table " \
      "--grub2-boot-info " \
      "--grub2-mbr /usr/share/cd-boot-images-amd64/images/boot/grub/i386-pc/boot_hybrid.img " \
      "-append_partition 2 0xef /usr/share/cd-boot-images-amd64/images/boot/grub/efi.img " \
      "-appended_part_as_gpt " \
      "--mbr-force-bootable " \
      "-eltorito-alt-boot " \
      "-e --interval:appended_partition_2:all:: " \
      "-no-emul-boot " \
      "-partition_offset 16 " \
      "-r " \
      "#{@extract_dir}"

    unless system(xorriso_cmd)
      Log.error("ISO 作成時にエラーが発生しました。")
      exit false
    end

    Log.info("ISO の作成が完了しました。")
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
    :distribution_version,
    :volume_id
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
    return unless Dir.exist?(dir) && system("mountpoint -q #{dir}")

    Log.info("マウントを解除しています (#{dir})...")
    Log.error("マウントの解除に失敗しました。") unless system("umount #{dir}")
  end
end

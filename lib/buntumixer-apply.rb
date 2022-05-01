#!/usr/bin/env ruby
# frozen_string_literal: true

require "log"
require "optparse"
require "fileutils"

params = {}
prog_conf = {}
opts = OptionParser.new do |opt|
  opt.on("-s", "--script SCRIPT", "適用するスクリプト (*.sh)") do |v|
    prog_conf[:script] = true
    params[:script] = v
  end

  opt.on("-d", "--dir DIR", "OS イメージのあるディレクトリー (*.sh)") do |v|
    prog_conf[:dir] = true
    params[:dir] = v
  end
end
opts.parse!(ARGV[1..])

if params.empty?
  puts opts.help
  exit true
end

unless prog_conf[:script]
  Log.error("スクリプトが指定されていません。")
  exit false
end

unless File.exist?(params[:script])
  Log.error("ファイルが存在しません。")
  exit false
end

unless prog_conf[:dir]
  Log.error("ディレクトリーが指定されていません。")
  exit false
end

unless Dir.exist?(params[:dir])
  Log.error("ディレクトリーが存在しません。")
  exit false
end

Log.info("スクリプトをコピーしています...")
FileUtils.cp(params[:script], params[:dir])

script_name = File.basename(params[:script])
Log.info("スクリプトを適用しています...")
Log.error("スクリプトの適用に失敗しました。") \
  unless system("chroot #{params[:dir]} /bin/bash #{script_name}")

Log.info("スクリプトを削除しています...")
FileUtils.rm("#{params[:dir]}/#{script_name}")

#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "log"
require "customize-livecd"

params = {}
prog_conf = {}
opts = OptionParser.new do |opt|
  opt.on("-s", "--src ISO", "Live CD イメージファイル (*.iso)") do |v|
    prog_conf[:src] = true
    params[:src] = v
  end
  opt.on("-v", "--v VERSION", "ディストリビューションのバージョン (例: 22.04)") do |v|
    prog_conf[:version] = true
    params[:version] = v
  end
  opt.on("-n", "--name NAME", "ディストリビューション名") do |v|
    prog_conf[:name] = true
    params[:name] = v
  end
end
opts.parse!(ARGV[1..])

if params.empty?
  puts opts.help
  exit true
end

unless prog_conf[:src]
  Log.error("ISO ファイルが指定されていません。")
  exit false
end

unless File.exist?(params[:src])
  Log.error("ファイルが見つかりません (#{params[:src]})。")
  exit false
end

unless prog_conf[:version]
  Log.error("バージョンが指定されていません。")
  exit false
end

unless prog_conf[:name]
  Log.error("ディストリビューション名が指定されていません。")
  exit false
end

my_linux = CustomLiveCD.new
my_linux.src_iso = params[:src]
my_linux.distribution_version = params[:version]
my_linux.distribution_name = params[:name]
my_linux.prep
p my_linux

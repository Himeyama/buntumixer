#!/usr/bin/env ruby
# frozen_string_literal: true

require "log"
require "customize-livecd"
require "optparse"

params = {}
prog_conf = {}
opts = OptionParser.new do |opt|
  opt.on("-o", "--output ISO", "Live CD イメージファイル (*.iso)") do |v|
    prog_conf[:dst] = true
    params[:dst] = v
  end
end
opts.parse!(ARGV[1..])

unless prog_conf[:dst]
  Log.error("ISO ファイルの保存先が指定されていません。")
  exit false
end

livecd = CustomLiveCD.new
livecd.dst_iso = params[:dst]
livecd.create

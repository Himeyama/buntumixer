#!/usr/bin/env ruby
# frozen_string_literal: true

require "log"
require "customize-livecd"

Log.info "作業ディレクトリーを削除しています..."
my_linux = CustomLiveCD.new
my_linux.clear

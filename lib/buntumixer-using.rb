#!/usr/bin/env ruby
# frozen_string_literal: true

$PROGRAM_NAME =~ %r{/([a-zA-z]+)-help$}
PROG = Regexp.last_match(1)

puts "使用法: #{PROG} <コマンド> [<引数>]"

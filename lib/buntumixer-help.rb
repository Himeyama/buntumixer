#!/usr/bin/env ruby
# frozen_string_literal: true

$PROGRAM_NAME =~ %r{/([a-zA-z]+)-help$}
PROG = Regexp.last_match(1)

puts "使用法: #{PROG} <コマンド> [<引数>]\n\n" \
  "   help        ヘルプを表示します。\n" \
  "   using       使用法を表示します。\n" \
  "   prepare     Live CD のインストールイメージを展開し、作業環境を準備します。\n" \
  "   create      ISO ファイルを作成します。\n" \
  "   apply       スクリプトを適用します。\n" \
  "   clear       作業ディレクトリーを片づけます。"

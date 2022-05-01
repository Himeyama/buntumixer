# frozen_string_literal: true

# 簡単なログを出力
class Log
  def self.red_txt(txt)
    "\033[31;1m#{txt}\033[0m"
  end

  def self.green_txt(txt)
    "\033[32;1m#{txt}\033[0m"
  end

  def self.info(txt)
    time = Time.now.strftime("%F %T")
    puts green_txt("#{time} #{txt}")
  end

  def self.error(txt)
    time = Time.now.strftime("%F %T")
    warn red_txt("#{time} #{txt}")
  end
end

module Refract
  class MultiProcessLogger
    ROOT = File.expand_path("./.refract/.logs/")
    def initialize
      FileUtils.mkdir_p(ROOT)
      @filename = File.expand_path(File.join(ROOT, "#{Process.pid}"))
    end

    def log(message)
      puts(message + "\n")
      open(@filename, 'a') { |f| f << message << "\n" }
    end

    def self.clear
      FileUtils.rm_rf(ROOT)
      FileUtils.mkdir_p(ROOT)
    end

    def self.all
      Dir.glob(File.join(ROOT, "*")).map do |fname|
        [File.basename(fname), File.read(fname).split("\n")]
      end
    end
  end
end

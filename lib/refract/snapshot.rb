module Refract
  class Snapshot
    attr_reader :path, :name, :whole_name, :percentage
    def initialize(path)
      @path = path
      @whole_name = File.basename(path)
      matches = whole_name.match(/__([\d\.]+)__(.*)/)

      if matches.length == 3
        @percentage = matches[1].to_f
        @name = matches[2]
      else
        @percentage = 0
        @name = whole_name
      end

      @sha = Pathname.new(path).each_filename.to_a[-2]
    end

    def at(sha)
      new_path = @path.sub(@sha, sha)
      Snapshot.new(sha)
    end

    def self.all(directory: )
      Dir.glob(directory + "/*.png").map { |f| Snapshot.new(f) }
    end
  end
end

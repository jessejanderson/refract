module Refract
  class Snapshot
    attr_reader :path, :name, :whole_name, :base_name, :percentage
    def initialize(path)
      @path = path
      @whole_name = File.basename(path)
      matches = whole_name.match(/__([\d\.]+)__(\d+)x(\d+)--(.*)/)

      if matches.length == 5
        @percentage = matches[1].to_f
        @width = matches[2]
        @height = matches[3]
        @name = matches[4]
        @base_name = "#{@width}x#{@height}--#{@name}"
      else
        @percentage = 0
        @width = 0
        @height = 0
        @name = whole_name
        @base_name = @name
      end

      @sha = Pathname.new(path).each_filename.to_a[-2]
    end

    def dimensions
      @dimensions ||= [@width, @height]
    end

    def self.all(directory: )
      Dir.glob(directory + "/*.png").map { |f| Snapshot.new(f) }
    end
  end
end

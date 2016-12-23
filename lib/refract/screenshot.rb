module Refract
  # Wraps an image file and pulls out metadata from the filename
  class Screenshot
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

    def dimension_s
      dimensions.join("x")
    end

    def timestamp
      File.mtime(@path)
    end

    def self.all(directory: )
      Dir.glob(directory + "/*.png").map { |f| Screenshot.new(f) }
    end
  end
end

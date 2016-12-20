module Refract
  class Snapshot
    attr_reader :path, :name
    def initialize(path)
      @path = path
      @name = File.basename(path)
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

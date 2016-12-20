module Refract
  class Commit
    attr_reader :sha
    def initialize(sha)
      @sha = sha
      @directory = ".refract/#{sha}"
    end

    def title
      @title ||= `git show --format="%h %s (%an)" -s #{@sha}`
    end

    def timestamp
      @timestamp ||= `git show  --format="%at" -s #{@sha}`.to_i
    end

    def images
      @images ||= Snapshot.all(directory: @directory)
    end

    def diffs
      @diffs ||= Dir.glob(@directory + "/*/").map do |dir|
        sha = File.basename(dir)
        Diff.new(self, Commit.new(sha))
      end
    end

    def destroy
      FileUtils.rm_rf(@directory)
    end

    def self.all
      Dir.glob(".refract/*").map { |d| Commit.new(File.basename(d)) }
    end
  end
end

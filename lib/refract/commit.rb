module Refract
  class Commit
    attr_reader :sha, :directory
    def initialize(sha)
      @sha = sha
      @directory = ".refract/#{sha}"
    end

    def self.from_rev(rev)
      self.new(`git rev-parse #{rev}`.strip)
    end

    def message
      load_metadata && @message
    end

    def author
      load_metadata && @author
    end

    def timeago
      load_metadata && @timeago
    end

    def diffs
      @diffs ||= Dir.glob(@directory + "/*/").map do |dir|
        sha = File.basename(dir)
        Diff.new(self, Commit.new(sha))
      end
    end

    def branch
      @branch ||= `git branch --points-at #{@sha}`.strip.sub(/^\*\s+/, '')
    end

    def destroy
      FileUtils.rm_rf(@directory)
    end

    def self.all
      Dir.glob(".refract/*")
        .select { |d| d != ".refract/.logs" }
        .map { |d| Commit.new(File.basename(d)) }
    end

    private

    def load_metadata
      @load_metadata ||= begin
        metadata = `git show --format="%s|%an|%cr" -s #{@sha}`.strip
        @message, @author, @timeago = metadata.split("|")
        true
      end
    end
  end
end

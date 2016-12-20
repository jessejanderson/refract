module Refract
  class Commit
    attr_reader :sha
    def initialize(sha)
      @sha = sha
      @directory = ".refract/#{sha}"
    end

    def self.from_rev(rev)
      self.new(`git rev-parse #{rev}`.strip)
    end

    def title
      @title ||= `git show --format="%s (%an) %h" -s #{@sha}`
    end

    def timestamp
      @timestamp ||= `git show  --format="%at" -s #{@sha}`.to_i
    end

    def timeago
      @timeago ||= `git show --format="%cr" -s #{@sha}`
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

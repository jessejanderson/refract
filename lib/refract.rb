require "fileutils"
require "capybara"
require "webrick"
require "erb"
require "pathname"
require "refract/cli"
require "refract/commit"
require "refract/diff"
require "refract/run"
require "refract/server"
require "refract/snapshot"
require "refract/version"

# TODO:
#  - Make the log come back to the browser
#  - better dimension handling
module Refract
  DEFAULT_PORT = 7777
  DEFAULT_SNAPSHOTS_FILE = "snapshots.rb"

  class << self
    attr_accessor :logger
  end

  module PutsLogger
    def self.log(message); puts(message); end
  end

  self.logger = PutsLogger

  RUNS = []

  def self.run(&block)
    RUNS << Run.new(&block)
  end

  def self.perform
    RUNS.each(&:perform)
    RUNS.clear
  end

  def self.log(message)
    logger.log(message)
  end

  def self.serve(port: DEFAULT_PORT)
    Server.serve(port: port)
  end
end

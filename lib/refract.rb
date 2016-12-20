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
#  - Display the percentage:
#    - compare with rmagick, store the percentage in the filename
#    - show the percentage in the UI
#  - A UI for overlaying diff on each image
#  - Run snapshots by clicking a button
#    - Make it run in the rails process
#    - Make the log come back to the browser
Capybara.register_driver :selenium_chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

module Refract
  DEFAULT_PORT = 7777

  class << self
    attr_accessor :logger
  end
  module PutsLogger
    def self.log(message); puts(message); end
  end

  module DebugLogger
    def self.log(message); Rails.logger.debug(message); end
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

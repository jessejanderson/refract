require "fileutils"
require "capybara"
require "webrick"
require "erb"
require "pathname"
require "refract/cli"
require "refract/commit"
require "refract/diff"
require "refract/logger/multi_process_logger"
require "refract/logger/puts_logger"
require "refract/run"
require "refract/server"
require "refract/session_proxy"
require "refract/screenshot"
require "refract/version"

module Refract
  DEFAULT_PORT = 7777
  DEFAULT_SCREENSHOTS_FILE = "screenshots.rb"

  class << self
    attr_accessor :logger
  end

  self.logger = Logger::PutsLogger.new

  def self.run(&block)
    @run = Run.new(&block)
  end

  def self.perform
    @run.perform
    @run
  end

  def self.log(message)
    logger.log("[#{Process.pid}][#{message}]")
  end

  def self.serve(port: DEFAULT_PORT)
    Server.serve(port: port)
  end
end

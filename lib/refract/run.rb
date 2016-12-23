module Refract
  class Run
    attr_reader :dimensions, :sha, :pids, :directory

    def initialize
      @sha = `git rev-parse head`.strip
      @directory = "./.refract/#{@sha}"
      @dimensions = []
      @before = ->(n) { "no-op" }
      @scripts = []
      @pids = []
      @driver = nil
      @timeout = 5
      yield(self)
    end

    def before(&block)
      @before = block
    end

    def script(&block)
      @scripts << block
    end

    def driver(driver_name = nil)
      if driver_name
        @driver = driver_name
      end
      @driver
    end

    def dimension(x, y)
      @dimensions << [x, y]
    end

    def perform
      if @scripts.none?
        raise("No scripts defined, nothing to run")
      end
      Logger::MultiProcessLogger.clear
      Refract.log("=> Refract @ #{@sha}")
      FileUtils.rm_rf(directory)
      @pids = @scripts.map do |script|
        Process.fork {
          Refract.logger = Logger::MultiProcessLogger.new
          s = Script.new(self) { |session|
            @before.call(session)
            script.call(session)
          }
          s.run
        }
      end
      Process.waitall
    rescue Exception => err
      $stderr.puts "\n\n#{err}\n\n"
      @pids.each { |pid| Process.kill("HUP", pid) }
    end

    private

    class Script
      def initialize(run, &block)
        @run = run
        @block = block
      end

      def run
        capybara_session = Capybara::Session.new(@run.driver)
        session_proxy = SessionProxy.new(@run, capybara_session)
        @block.call(session_proxy)
      ensure
        Refract.log("Finished Run")
        begin
          capybara_session.driver.quit
        rescue NoMethodError
          # some drivers (eg Capybara::Webkit) don't support this
        end
      end
    end
  end
end

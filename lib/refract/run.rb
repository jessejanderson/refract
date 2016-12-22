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
      MultiProcessLogger.clear
      Refract.log("=> Refract @ #{@sha}")
      FileUtils.rm_rf(directory)
      # Refract.log("   => fork? #{Process.respond_to?(:fork)}")
      @pids = @scripts.map do |script|
        # Process.fork {
          Refract.logger = MultiProcessLogger.new
          s = Script.new(self) { |session|
            @before.call(session)
            script.call(session)
          }
          s.run
        # }
      end
      # Process.waitall
    rescue Exception => err
      $stderr.puts "\n\n#{err}\n\n"
      #   @pids.each { |pid| Process.kill("HUP", pid) }
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

    # Like a Capybara session, but:
    # - waits for turbolinks whenever you do anything
    # - makes a log entry whenever you do anything
    class SessionProxy
      def initialize(run, session)
        @run = run
        @session = session
      end

      def method_missing(method_name, *args, &block)
        if @session.respond_to?(method_name)
          Refract.log("-> #{method_name} #{args.map(&:inspect).join(", ")}")
          result = @session.public_send(method_name, *args, &block)
          wait_for_turbolinks
          result
        else
          super
        end
      end

      def snapshot(img_name)
        begin
          prev_dimension = @session.driver.browser.manage.window.size
        rescue
          prev_dimension = OpenStruct.new(height: 0, width: 0)
        end

        @run.dimensions.each do |(x, y)|
          resize_window_to(x, y)
          wait_for_turbolinks
          save_screenshot(File.join(@run.directory, "#{x}x#{y}--#{img_name}.png"))
        end
        resize_window_to(prev_dimension.height, prev_dimension.width)
      end

      private

      def resize_window_to(x, y)
        @session.driver.browser.manage.window.resize_to(x, y)
      rescue StandardError => err
        Refract.log(" ** Failed to resize browser: #{err}")
      end

      def wait_for_turbolinks
        Timeout.timeout(@timeout) do
          loop until @session.evaluate_script('jQuery && jQuery.active').zero?
        end
        # Let any JavaScripty stuff finish:
        sleep 0.5
      rescue
      end
    end
  end
end

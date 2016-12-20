module Refract
  class Run
    attr_reader :dimensions, :sha

    def initialize
      @sha = `git rev-parse head`.strip
      @dimensions = []
      @before = ->(n) { "no-op" }
      @script = ->(n) { raise("Script must be defined") }
      yield(self)
    end

    def before(&block)
      @before = block
    end

    def script(&block)
      @script = block
    end

    def dimension(x, y)
      @dimensions << [x, y]
    end

    def perform
      Refract.log("=> Refract @ #{@sha}")
      capybara_session = Capybara::Session.new(:selenium_chrome)
      session_proxy = SessionProxy.new(self, capybara_session)
      @before.call(session_proxy)
      @script.call(session_proxy)
    ensure
      capybara_session.driver.browser.close
    end

    private

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
        prev_dimension = @session.driver.browser.manage.window.size
        @run.dimensions.each do |(x, y)|
          @session.driver.browser.manage.window.resize_to(x, y)
          wait_for_turbolinks
          save_screenshot("./.refract/#{@run.sha}/#{x}x#{y}--#{img_name}.png")
        end

        @session.driver.browser.manage.window.resize_to(prev_dimension.width, prev_dimension.height)
      end

      private

      def wait_for_turbolinks
        Timeout.timeout(5) do
          loop until @session.evaluate_script('jQuery && jQuery.active').zero?
        end
        # Let any JavaScripty stuff finish:
        sleep 0.5
      end
    end
  end
end

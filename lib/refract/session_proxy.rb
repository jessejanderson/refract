module Refract
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

    def screenshot(img_name)
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

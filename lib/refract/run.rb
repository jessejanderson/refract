module Refract
  class Run
    attr_reader :session

    def initialize(&block)
      @script = block
      @sha = `git rev-parse head`.strip
    end

    def snapshot(img_name)
      wait_for_turbolinks
      save_screenshot("./.refract/#{@sha}/#{img_name}.png")
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

    def wait_for_turbolinks
      Timeout.timeout(5) do
        loop until @session.evaluate_script('jQuery.active').zero?
      end
      # Let any JavaScripty stuff finish:
      sleep 0.1
    end

    def perform
      Refract.log("=> Refract @ #{@sha}")
      @session = Capybara::Session.new(:selenium_chrome)
      login
      @script.call(self)
      @session.driver.browser.close
    end

    private

    def login
      visit "http://resources.pco.dev/"
      fill_in("email", with: "pico@pco.bz")
      fill_in("password", with: "password")
      click_button("Submit")
      first(".btn").click
    end
  end
end

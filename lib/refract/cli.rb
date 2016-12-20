module Refract
  module CLI
    COMMANDS = [
      RUN = "run",
      SERVE = "serve"
    ]

    # @param command [Array<String>] `ARGV`
    # @return void
    def self.dispatch(command)
      case command[0]
      when RUN
        ruby_file = command[1] || DEFAULT_SNAPSHOTS_FILE
        load(ruby_file)
        Refract.perform
      when SERVE
        Refract.serve
      else
        usage("{#{COMMANDS.join("|")}} ...")
      end
    end


    def self.usage(expected_usage)
      puts "Unexpected arguments."
      puts "Usage: refract #{expected_usage}"
    end
  end
end

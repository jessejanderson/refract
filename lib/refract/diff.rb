require "set"
module Refract
  class Diff
    def capture_stderr
      backup_stderr = STDERR.dup
      begin
        Tempfile.open("captured_stderr") do |f|
          STDERR.reopen(f)
          yield
          f.rewind
          f.read
        end
      ensure
        STDERR.reopen backup_stderr
      end
    end

    attr_reader :base, :head, :directory

    def initialize(base_sha, head_sha)
      @base = base_sha.is_a?(String) ? Commit.new(base_sha) : base_sha
      @head = head_sha.is_a?(String) ? Commit.new(head_sha) : head_sha

      @directory = ".refract/#{@base.sha}/#{@head.sha}"
    end

    def screenshots
      Screenshot.all(directory: @directory)
    end

    def dimensions
      Set.new(screenshots.map(&:dimensions))
    end

    def exist?
      screenshots.any?
    end

    def create
      base_dir = @base.directory
      head_dir = @head.directory
      target_dir = @directory
      FileUtils.mkdir_p(target_dir)

      Dir.glob(base_dir + "/*.png").each do |base_img_path|
        filename = File.basename(base_img_path)
        head_img_path = "#{head_dir}/#{filename}"
        target_img_path = "#{target_dir}/#{filename}"
        begin
          base_dimensions = `identify -format '%G' '#{base_img_path}'`.split("x")
          base_pixels = base_dimensions[0].to_i * base_dimensions[1].to_i
          different_pixels = capture_stderr {
            `compare -metric AE '#{base_img_path}' '#{head_img_path}' '#{target_img_path}'`
          }


          percentage = (different_pixels.to_f / base_pixels.to_f) * 100
          Refract.log("#{filename} diff: #{different_pixels} / #{base_pixels} => #{percentage}")

          target_img_with_perc_path = "#{target_dir}/__#{percentage.round(4)}__#{filename}"
          File.rename(target_img_path, target_img_with_perc_path)
        rescue StandardError => err
          Refract.log("Compare failed: #{err}")
        end
      end
    end

    def timeago
      if screenshots.any?
        s = Time.now.to_i - screenshots.first.timestamp.to_i
        days, rem = s.divmod(60 * 60 * 24)
        hours, rem = rem.divmod(60 * 60)
        minutes, rem = rem.divmod(60)
        if days > 0
          "#{days} days ago"
        elsif hours > 0
          "#{hours} hours ago"
        elsif minutes > 0
          "#{minutes} minutes ago"
        else
          "just now"
        end
      else
        "Never"
      end
    end

    def percentage
      if screenshots.any?
        total = screenshots.map(&:percentage).inject(&:+)
        (total / screenshots.length).round(4)
      else
        0
      end
    end

    def destroy
      FileUtils.rm_rf(@directory)
    end

    module NullDiff
      module_function
      def timeago; "--"; end
      def dimensions; []; end
      def screenshots; []; end
    end
  end
end

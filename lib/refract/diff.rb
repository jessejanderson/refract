module Refract
  class Diff
    def self.create(base_sha, head_sha)
      base_dir = ".refract/#{base_sha}"
      head_dir = ".refract/#{head_sha}"

      target_dir = ".refract/#{base_sha}/#{head_sha}"
      FileUtils.mkdir_p(target_dir)
      Dir.glob(base_dir + "/*.png").each do |base_img_path|
        filename = File.basename(base_img_path)
        head_img_path = "#{head_dir}/#{filename}"
        target_img_path = "#{target_dir}/#{filename}"
        base_dimensions = `identify -format '%G' '#{base_img_path}'`.split("x")
        base_pixels = base_dimensions[0].to_i * base_dimensions[1].to_i
        different_pixels = capture_stderr {
          `compare -metric AE '#{base_img_path}' '#{head_img_path}' '#{target_img_path}'`
        }


        percentage = (different_pixels.to_f / base_pixels.to_f) * 100
        Refract.log("#{filename} diff: #{different_pixels} / #{base_pixels} => #{percentage}")

        target_img_with_perc_path = "#{target_dir}/__#{percentage.round(1)}__#{filename}"
        File.rename(target_img_path, target_img_with_perc_path)
      end
    end


    def self.capture_stderr
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

    def snapshots
      @snapshots ||= Snapshot.all(directory: @directory)
    end

    def percentage
      @percentage ||= begin
        total = snapshots.map(&:percentage).inject(&:+)
        (total / snapshots.length).round(1)
      end
    end

    def destroy
      FileUtils.rm_rf(@directory)
    end
  end
end

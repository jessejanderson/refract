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
        `compare '#{base_img_path}' '#{head_img_path}' '#{target_img_path}'`
      end
    end

    attr_reader :base, :head, :directory

    def initialize(base_sha, head_sha)
      @base = base_sha.is_a?(String) ? Commit.new(base_sha) : base_sha
      @head = head_sha.is_a?(String) ? Commit.new(head_sha) : head_sha
      @directory = ".refract/#{@base.sha}/#{@head.sha}"
    end

    def images
      @images ||= Snapshot.all(directory: @directory)
    end

    def destroy
      FileUtils.rm_rf(@directory)
    end
  end
end

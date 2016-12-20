module Refract
  module Server
    module Templates
      def self.build_template(template_name)
        full_name = File.expand_path(File.join(__FILE__, "../templates/#{template_name}"))
        erb_text = File.read(full_name)
        ERB.new(erb_text)
      end

      HOME = build_template("home.erb")
      DIFF = build_template("diff.erb")
    end

    def self.serve(port: 7777)
      root = File.expand_path("./.refract")
      server = WEBrick::HTTPServer.new(Port: port)

      server.mount("/img", WEBrick::HTTPServlet::FileHandler, root)
      server.mount("/", Servlet)
      trap('INT') { server.shutdown }

      host = "http://localhost:#{port}"
      Refract.log("Starting on #{host} (#{root})")
      # Mac only
      system("open", host)

      server.start
    end

    class Servlet < WEBrick::HTTPServlet::AbstractServlet
      def get_segments(request)
        request.path.sub(/^\//, "").split("/")
      end

      def do_GET(request, response)
        segments = get_segments(request)
        case segments.shift
        when nil
          home(request, response)
        when "diff"
          diff(request, response, segments[0], segments[1])
        else
          not_found(request, response)
        end
      end

      def do_POST(request, response)
        segments = get_segments(request)
        case segments.shift
        when "delete"
          base_sha = segments[0]
          head_sha = segments[1]
          if head_sha.nil?
            Commit.new(base_sha).destroy
          else
            Diff.new(base_sha, head_sha).destroy
          end
          redirect(response, "/")
        when "diff"
          base_sha = request.query["base_sha"]
          head_sha = request.query["head_sha"]
          Diff.create(base_sha, head_sha)
          redirect(response, "/diff/#{base_sha}/#{head_sha}")
        when "snapshot"
          load("snapshots.rb")
          Refract.perform
          redirect(response, "/")
        else
          not_found(request, response)
        end
      end

      def home(request, response)
        @master_sha = `git rev-parse master`.strip
        @current_sha = `git rev-parse head`.strip
        @commits = Refract::Commit.all
        response.status = 200
        response.body = Templates::HOME.result(binding)
      end

      def not_found(request, response)
        response.status = 404
        response.body = "Nothing here!"
      end

      def redirect(response, path)
        response.status = 302
        response["Location"] = path
      end

      def diff(request, response, base_sha, head_sha)
        @diff = Refract::Diff.new(base_sha, head_sha)
        response.status = 200
        response.body = Templates::DIFF.result(binding)
      end
    end
  end
end

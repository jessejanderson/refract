require "uri"

module Refract
  module Server
    ASSET_PATH = File.expand_path(File.join(__FILE__, "../assets/"))
    def self.serve(port: 7777)
      root = File.expand_path("./.refract")
      server = WEBrick::HTTPServer.new(Port: port)

      server.mount("/img", WEBrick::HTTPServlet::FileHandler, root)
      server.mount("/assets", WEBrick::HTTPServlet::FileHandler, ASSET_PATH)
      server.mount("/", Servlet)
      trap('INT') { server.shutdown }

      host = "http://localhost:#{port}"
      Refract.log("Starting on #{host} (#{root})")

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
        when "run"
          response.status = 200
          response.body = build_template("run.erb")
        when "hide"
          hidden_s = read_cookie(request, "hidden") || ""
          new_hidden = segments.shift
          if new_hidden
            hidden_a = hidden_s.split("|")
            hidden_a << new_hidden
            next_hidden_s = hidden_a.join("|")
          else
            next_hidden_s = ""
          end

          write_cookie(response, "hidden", next_hidden_s)

          redirect(response, "/")
        when "setting"
          write_cookie(response, segments[0], segments[1])
          redirect(response, "/")
        else
          not_found(request, response)
        end
      end

      def do_POST(request, response)
        segments = get_segments(request)
        case segments.shift
        when "diff"
          base_sha = request.query["base_sha"]
          head_sha = request.query["head_sha"]
          write_cookie(response, "base_sha", base_sha)
          if !base_sha.empty?
            diff = Diff.new(base_sha, head_sha)
            if request.query["force_update"] || !diff.exist?
              diff.create
            end
          end
          redirect(response, "/")
        when "snapshot"
          load(DEFAULT_SNAPSHOTS_FILE)
          Thread.new { Refract.perform }
          redirect(response, "/run")
        else
          not_found(request, response)
        end
      end

      def home(request, response)
        @all_commits = Refract::Commit.all
        @current_commit = Refract::Commit.from_rev("head")

        base_sha = read_cookie(request, "base_sha") || (@all_commits.any? && @all_commits.first.sha)
        write_cookie(response, "base_sha", base_sha)

        hidden_s = read_cookie(request, "hidden") || ""
        @hidden_snapshots = hidden_s.split("|")
        @request = request
        @dimension = read_cookie(request, "dimension")
        @righthand = read_cookie(request, "righthand") || "diff"
        @size = read_cookie(request, "size") || "small"
        if base_sha && !base_sha.empty?
          @base_commit = Refract::Commit.from_rev(base_sha)
          @diff = Refract::Diff.new(@current_commit.sha, @base_commit.sha)
          if !@diff.exist?
            @diff.create
          end
        else
          @base_commit = nil
          @diff = Diff::NullDiff
        end

        response.status = 200
        response.body = build_template("home.erb")
      end

      def not_found(request, response)
        response.status = 404
        response.body = "Nothing here!"
      end

      def redirect(response, path)
        response.status = 302
        response["Location"] = path
      end

      def build_template(template_name)
        template = File.read(File.expand_path(File.join(__FILE__, "../templates/#{template_name}")))
        content = nil
        locals = binding
        ERB.new(template, nil, nil, "content").result(locals)
        layout = File.read(File.expand_path(File.join(__FILE__, "../templates/layout.erb")))
        ERB.new(layout).result(locals)
      end

      def read_cookie(request, name)
        c = request.cookies.find { |c| c.name == name }
        c && c.value
      end

      def write_cookie(response, name, value)
        cookie = WEBrick::Cookie.new(name,value)
        cookie.path = "/"
        response.cookies.push(cookie)
      end
    end
  end
end

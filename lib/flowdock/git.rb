require "multi_json"
require "net/https"
require "cgi"

require "flowdock/git/builder"

module Flowdock
  class Git
    class TokenError < StandardError; end
    API_ENDPOINT = "https://api.flowdock.com/v1/git"

    class << self
      def post(ref, from, to, options = {})
        git = Git.new(options)
        git.post(Git::Builder.new(git.repo, ref, from, to))
      end

      def background_post(ref, from, to, options = {})
        git = Git.new(options)
        git.background_post(Git::Builder.new(git.repo, ref, from, to))
      end
    end

    def initialize(options = {})
      @options = options
      @token = options[:token] || config["flowdock.token"] || raise(TokenError.new("Flowdock API token not found"))
      @commit_url = options[:commit_url] || config["flowdock.commit-url-pattern"] || nil
      @diff_url = options[:diff_url] || config["flowdock.diff-url-pattern"] || nil
      @repo_url = options[:repo_url] || config["flowdock.repository-url"] || nil
    end

    # Send git push notification to Flowdock
    def post(data)
      uri = URI.parse("#{API_ENDPOINT}/#{([@token] + tags).join('+')}")
      req = Net::HTTP::Post.new(uri.path)

      payload_hash = data.to_hash
      if @repo_url
        payload_hash[:repository][:url] = @repo_url
      end
      if @commit_url
        payload_hash[:commits].each do |commit|
          commit[:url] = @commit_url % commit[:id]
        end
      end
      if @diff_url
        payload_hash[:compare] = @diff_url % [payload_hash[:before], payload_hash[:after]]
      end

      req.set_form_data(:payload => MultiJson.encode(payload_hash))
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.use_ssl = true
      end

      http.start { |http| http.request(req) }
    end

    # Create and post notification in background process. Avoid blocking the push notification.
    def background_post(data)
      pid = Process.fork
      if pid.nil?
        Grit::Git.with_timeout(600) do
          post(data) # Child
        end
      else
        Process.detach(pid) # Parent
      end
    end

    def repo
      @repo ||= Grit::Repo.new(@options[:repo] || Dir.pwd)
    end

    private

    # Flowdock tags attached to the push notification
    def tags
      if @options[:tags]
        @options[:tags]
      else
        config["flowdock.tags"].to_s.split(",")
      end.map do |t|
        CGI.escape(t)
      end
    end

    def config
      @config ||= Grit::Config.new(repo)
    end
  end
end

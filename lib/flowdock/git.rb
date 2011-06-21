require "multi_json"
require "net/https"
require "cgi"

require "flowdock/git/builder"

module Flowdock
  class Git
    class TokenError < StandardError; end
    API_ENDPOINT = "https://api.flowdock.com/v1/git"

    def initialize(ref, from, to, options = {})
      @ref = ref
      @from = from
      @to = to

      @options = options

      @token = options[:token] || config["flowdock.token"] || raise(TokenError.new("Flowdock API token not found"))
    end

    def post
      uri = URI.parse("#{API_ENDPOINT}/#{([@token] + tags).join('+')}")
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(:payload => MultiJson.encode(payload))
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.use_ssl = true
      end

      http.start { |http| http.request(req) }
    end

    def payload
      Builder.new(repo, @ref, @from, @to).to_hash
    end

    def tags
      if @options[:tags]
        @options[:tags]
      else
        config["flowdock.tags"].to_s.split(",")
      end.map do |t|
        CGI.escape(t)
      end
    end

    private

    def repo
      @repo ||= Grit::Repo.new(@options[:repo] || Dir.pwd)
    end

    def config
      @config ||= Grit::Config.new(repo)
    end
  end
end

require "multi_json"

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

      @token = options[:token] || raise(TokenError.new("Flowdock API token not found"))
    end

    def post
      uri = URI.parse("#{API_ENDPOINT}/#{@token}")
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
      # Payload generation goes here
    end

    private

    def repo
      @repo ||= Grit::Repo.new(@options[:repo] || Dir.pwd)
    end
  end
end

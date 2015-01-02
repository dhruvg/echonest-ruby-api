require 'httparty'
require 'multi_json'

module Echonest
  class Base
    class EchonestConnectionError < Exception; end

    def initialize(api_key)
      @api_key = api_key
      @base_uri = "http://developer.echonest.com/api/v4/"
    end

    def get_response(options = {})
      get(endpoint, options)
    end

    def post_response(options = {}, headers = {}, file_path = nil)
      post(endpoint, options, headers, file_path)
    end

    def entity_name
      self.class.to_s.split('::').last.downcase
    end

    def endpoint
      calling_method = caller[1].split('`').last[0..-2]
      "#{ entity_name }/#{ calling_method }"
    end

    # Gets the base URI for all API calls
    #
    # Returns a String
    def self.base_uri
      "http://developer.echonest.com/api/v#{ Base.version }/"
    end

    # The current version of the Echonest API to be supported.
    #
    # Returns a Fixnum
    def self.version
      4
    end

    # audio_summary is a Hash of acoustic characteristics and values
    def cleaned_audio_summary(audio_summary)
      return nil if !audio_summary
      # There is an weird issue in audio summary responses where speechiness is nil for certain tracks. I believe this
      # is due to the track having no speech. To play nice with math, I convert nil to 0.
      audio_summary[:speechiness] = 0 if audio_summary[:speechiness].nil?
      audio_summary
    end

    # Performs a simple HTTP get on an API endpoint.
    #
    # Examples:
    #     get('artist/biographies', results: 10)
    #     #=> Array of Biography objects.
    #
    # Raises an +ArgumentError+ if the Echonest API responds with
    # an error.
    #
    # * +endpoint+ - The name of an API endpoint as a String
    # * +options+ - A Hash of options to pass to the end point.
    #
    # Returns a response as a Hash
    def get(endpoint, options = {})
      options.merge!(api_key: @api_key,
                     format: "json")

      httparty_options = { query_string_normalizer: HTTParty::Request::NON_RAILS_QUERY_STRING_NORMALIZER,
                           query: options }

      response = HTTParty.get("#{ Base.base_uri }#{ endpoint }", httparty_options)
      handle_response(endpoint, options, :get, response)
    end

    # Performs a simple HTTP post on an API endpoint.
    #
    # Examples:
    #     post('track/upload', url: 'http://www.foobar.com/baz.mp3')
    #     #=> JSON response as hash
    #
    # Raises an +ArgumentError+ if the Echonest API responds with
    # an error.
    #
    # * +endpoint+ - The name of an API endpoint as a String
    # * +options+ - A Hash of options to pass to the end point.
    # * +headers+ - A Hash of headers to pass to the end point.
    # # +file_path+ - Path to file to post to the end point.
    #
    # Returns a response as a Hash
    def post(endpoint, options = {}, headers = {}, file_path = nil)
      options.merge!(api_key: @api_key,
                     format: 'json')

      httparty_options = { query_string_normalizer: HTTParty::Request::NON_RAILS_QUERY_STRING_NORMALIZER,
                           query: options,
                           headers: { 'Content-Type' => 'multipart/form-data' }.merge!(headers) }
      if file_path
        f = File.open(file_path)
        httparty_options[:body_stream] = f
        httparty_options[:headers]['Transfer-Encoding'] = 'chunked'
        httparty_options[:headers]['Content-Length'] = f.size.to_s
      end

      response = HTTParty.post("#{ Base.base_uri }#{ endpoint }", httparty_options)

      f.close() if file_path
      handle_response(endpoint, options, :post, response)
    end

    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{ cmd }#{ ext }")
          return exe if File.executable? exe
        }
      end
      return nil
    end

    private

    # Handles response from HTTParty request
    def handle_response(endpoint, options, http_method, response)
      json = MultiJson.load(response.body, symbolize_keys: true)
      response_code = json[:response][:status][:code]

      if response_code.eql?(0)
        json[:response]
      elsif response_code.eql?(3)
        # Rate limited - wait 90 seconds and try request again
        sleep 90
        self.send(http_method, endpoint, options)
      else
        raise Echonest::Error.new(response_code, response),
              "Error code #{ response_code } with response: #{ response }"
      end
    end
  end
end

require "rubygems"
require "bundler/setup"
require 'httparty'
require 'multi_json'
require_relative 'base'

module Echonest
  class Track < Echonest::Base

    def initialize(api_key)
      @api_key = api_key
    end

    def upload(options = {})
      raise ArgumentError, 'You must include a url for the mp3' if options[:url].nil?
      post_response(options)[:track]
    end

    def profile(options = {})
      raise ArgumentError, 'You must include a tracking id' if options[:id].nil?
      options.merge!(bucket: 'audio_summary')
      get_response(options)[:track]
    end

  end
end

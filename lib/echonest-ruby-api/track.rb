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

    def upload(file_path, options = {})
      raise ArgumentError, 'You must include a file path for the mp3' if file_path.nil?
      options[:filetype] = 'mp3'
      post_response(options, { 'Content-Type' => 'application/octet-stream' }, file_path)[:track]
    end

    def profile(options = {})
      raise ArgumentError, 'You must include a tracking id' if options[:id].nil?
      options.merge!(bucket: 'audio_summary')
      response = get_response(options)[:track]
      response[:audio_summary] = cleaned_audio_summary(response[:audio_summary])
      response
    end

  end
end

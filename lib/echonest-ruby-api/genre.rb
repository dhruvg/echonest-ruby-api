require "rubygems"
require "bundler/setup"
require_relative 'base'

module Echonest

  class Genre < Echonest::Base

    attr_accessor :name

    def initialize(api_key, name = nil)
      @name = name
      @api_key = api_key
    end

    def artists(options = { results: 100 })
      response = get_response(results: options[:results], name: @name)
      response[:artists].collect do |a|
        Artist.new(@api_key, a[:name], nil, a[:id])
      end
    end
  end
end
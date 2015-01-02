require 'spec_helper'
require 'mocha/setup'

describe Echonest::Track do
  spec = Gem::Specification.find_by_name("echonest-ruby-api")
  gem_root = spec.gem_dir

  it 'should initialize correct' do
    a = Echonest::Track.new('abc234')
    a.should be_a Echonest::Track
  end

  describe "#profile" do
    it "should return the tracking info w/ audio_summary for a given tracking id" do
      VCR.use_cassette('track_profile') do
        a = Echonest::Track.new('BNOAEBT3IZYZI6WXI')
        options = { id: 'TRTLKZV12E5AC92E11' }
        a.profile(options).keys.should include :id, :audio_summary, :status
      end
    end

    it "raises an ArgumentError if id is not provided" do
      VCR.use_cassette('track_profile') do
        a = Echonest::Track.new('BNOAEBT3IZYZI6WXI')
        options = { id: nil }
        expect{a.profile(options)}.to raise_exception(ArgumentError)
      end
    end
  end

  describe "#upload" do
    it "should upload the given mp3 and return a tracking id" do
      VCR.use_cassette('track_upload') do
        a = Echonest::Track.new('BNOAEBT3IZYZI6WXI')
        a.upload("#{gem_root}/fixtures/test.mp3").keys.should include :id, :status
      end
    end

    it "raises an ArgumentError if mp3 file path is not provided" do
      VCR.use_cassette('track_upload') do
        a = Echonest::Track.new('BNOAEBT3IZYZI6WXI')
        expect{a.upload(nil)}.to raise_exception(ArgumentError)
      end
    end
  end
end
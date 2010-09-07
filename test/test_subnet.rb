require 'helper'

class TestSubnet < Test::Unit::TestCase
  include Rack::Test::Methods

  context "A subnet application" do
#    setup do
#      PORT = 6379
#      OPTIONS = {:port => PORT, :db => 15, :timeout => 1}
#      @r = prepare Redis.new(OPTIONS)
#    end

    def app
      Sinatra::Application
    end

    should "catch bad requests" do
      post '/'
      assert_equal 404, last_response.status
      post '/sites/rennes', :site => 'rennes'
      assert_equal 404, last_response.status
    end

    should "allocate subnets until there are no more available" do
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal "10.156.0.0\n", last_response.body
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal "10.156.1.0\n", last_response.body
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 404, last_response.status
    end
  end
end

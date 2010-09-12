require 'helper'

class TestSubnet < Test::Unit::TestCase
  include Rack::Test::Methods

  context "A subnet application" do
    def app
      Sinatra::Application
    end

    should "catch bad requests" do
      post '/'
      assert_equal 404, last_response.status
      post '/sites/rennes', :site => 'rennes'
      assert_equal 404, last_response.status
    end

    should "not fail when deleting subnets from a non-existing job" do
      delete '/sites/rennes/jobs/123456/subnets'
      assert_equal 204, last_response.status
    end

    should "allocate subnets until there are no more available" do
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 200, last_response.status
      assert_equal "10.156.0.0\n", last_response.body
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 200, last_response.status
      assert_equal "10.156.1.0\n", last_response.body
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 404, last_response.status
    end

    should "allow deleting subnets for a job" do
      delete '/sites/rennes/jobs/359758/subnets'
      assert_equal 204, last_response.status
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 200, last_response.status
      assert_equal "10.156.0.0\n", last_response.body
    end
  end
end

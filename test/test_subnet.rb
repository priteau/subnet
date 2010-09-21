require 'helper'

class TestSubnet < Test::Unit::TestCase
  include Rack::Test::Methods

  context "A subnet application" do
    def app
      Sinatra::Application
    end

    setup do
      WebMock.stub_request(:get, 'https://api.grid5000.fr/2.0/grid5000').to_return(File.new(File.dirname(__FILE__) + '/../test/fixtures/root.json'))
      WebMock.stub_request(:get, 'https://api.grid5000.fr/2.0/grid5000/sites').to_return(File.new(File.dirname(__FILE__) + '/../test/fixtures/sites.json'))
      WebMock.stub_request(:get, 'https://api.grid5000.fr/2.0/grid5000/sites/rennes').to_return(File.new(File.dirname(__FILE__) + '/../test/fixtures/rennes.json'))
      WebMock.stub_request(:get, 'https://api.grid5000.fr/2.0/grid5000/sites/rennes/jobs').to_return(File.new(File.dirname(__FILE__) + '/../test/fixtures/jobs.json'))

      set :session, Restfully::Session.new(:base_uri => 'https://api.grid5000.fr/2.0/grid5000')
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

    should "allocate subnets until there are no more available, and create resources" do
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 200, last_response.status
      assert_equal "10.156.0.0\n", last_response.body
      get '/sites/rennes/jobs/359758/subnets/10.156.0.0'
      assert_equal 200, last_response.status
      assert_equal (1..254).map { |i| "10.156.0.#{i}\n" }.join(""), last_response.body
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 200, last_response.status
      assert_equal "10.156.1.0\n", last_response.body
      get '/sites/rennes/jobs/359758/subnets/10.156.1.0'
      assert_equal (1..254).map { |i| "10.156.1.#{i}\n" }.join(""), last_response.body
      post '/sites/rennes/jobs/359758/subnets'
      assert_equal 404, last_response.status
      get '/sites/rennes/jobs/359758/subnets/10.156.2.0'
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

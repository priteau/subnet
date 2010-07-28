$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'test/unit'

require 'subnet'
require 'rack/test'

class TestSubnet < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_bad_request
    post '/'
    assert_equal 400, last_response.status
    post '/', :job_id => 357995
    assert_equal 400, last_response.status
    post '/', :site => 'rennes'
    assert_equal 400, last_response.status
  end

  def test_post
    post '/', :job_id => 357995, :site => 'rennes'
    assert_equal '10.136.0.0', last_response.body
    post '/', :job_id => 357995, :site => 'rennes'
    assert_equal '10.136.1.0', last_response.body
    post '/', :job_id => 357995, :site => 'rennes'
    assert_equal 404, last_response.status
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'shoulda'
require 'rack/test'
require 'webmock/test_unit'

require 'subnet'

class Test::Unit::TestCase
  include WebMock
end

def prepare(redis)
  begin
    redis.flushdb
    redis.select 15
    redis
  rescue Errno::ECONNREFUSED
    puts <<-EOS
      Cannot connect to Redis.

      Make sure Redis is running on localhost, port 6379.
      This testing suite connects to the database 15.

      To install redis:
        visit <http://code.google.com/p/redis/>.

      To start the server:
        rake start

      To stop the server:
        rake stop
    EOS
    exit 1
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'rack/test'

require 'subnet'

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

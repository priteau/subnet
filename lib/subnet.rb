require 'bundler'
Bundler.setup

require 'redis'
require 'restfully'
require 'sinatra'

session = Restfully::Session.new(:configuration_file => ENV['RESTFULLY_CONFIG'])
grid = session.root

redis = Redis.new
redis.flushall

def subnets_key(site)
  "G5K::#{site.capitalize}::Subnets"
end

def jobs_key(site)
  "G5K::#{site.capitalize}::Jobs"
end

def job_key(site, job_id)
  "G5K::#{site.capitalize}::Jobs::#{job_id}"
end

(0..10).each do |i|
  redis.rpush(subnets_key('rennes'), '10.136.%d.0' % i)
end

Thread.new do
  while true
    sleep 60
    grid.sites.map { |s| s['uid'] }.each do |site|
      jobs = redis.smembers(jobs_key(site))
      jobs.each do |job_id|
        begin
          job = grid.sites[site.to_sym].jobs[job_id.to_sym]
          if job['state'] != 'running'
            job_subnets = redis.smembers(job_key(site, job_id))
            job_subnets.each do |subnet|
              redis.rpush(subnets_key(site), subnet)
            end
            redis.del(job_key(site, job_id))
            redis.srem(jobs_key(site), job_id)
          end
        rescue => e
          puts e
          next
        end
      end
    end
  end
end

post '/' do
  job_id = params[:job_id]
  site = params[:site]
  return 400 if job_id.nil? || site.nil?

# job = grid.sites[site.to_sym].jobs[job_id.to_sym]
# return 403 if job['state'] != 'running' # || job['user_uid'] != user

  subnet = redis.lpop(subnets_key(site))
  if subnet
    redis.sadd(job_key(site, job_id), subnet)
    redis.sadd(jobs_key(site), job_id)
    return subnet + "\n"
  else
    return 404
  end
end

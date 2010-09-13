require 'bundler/setup'

require 'redis'
require 'restfully'
require 'sinatra'

def subnets_key(site)
  "G5K::#{site.capitalize}::Subnets"
end

def jobs_key(site)
  "G5K::#{site.capitalize}::Jobs"
end

def job_key(site, job_id)
  "G5K::#{site.capitalize}::Jobs::#{job_id}"
end

configure do
  @subnets = {
    'bordeaux' => [ 128 ],
    'grenoble' => [ 180 ],
    'lille' => [ 136 ],
    'lyon' => [ 140 ],
    'nancy' => [ 144 ],
    'orsay' => [ 148, 152 ],
    'rennes' => [ 156 ],
    'sophia' => [ 164 ],
    'toulouse' => [ 160 ]
  }
end

configure :production do
  set :session, Restfully::Session.new(:configuration_file => ENV['RESTFULLY_CONFIG'])

  redis = Redis.new
  set :redis, redis

  @subnets.each do |site, subnets|
    subnets.each do |subnet|
      (0..255).each { |i| redis.rpush(subnets_key(site), "10.#{subnet}.#{i}.0") }

      # KaVLAN? https://www.grid5000.fr/mediawiki/index.php/Xen_related_tools#choose_static_ip_address
      (0..255).each { |i| redis.rpush(subnets_key(site), "10.#{subnet + 2}.#{i}.0") }

      # Don't include subnet 255 because the last two IPs are used by the infrastructure
      # (DHCP server and gateway)
      (0..254).each { |i| redis.rpush(subnets_key(site), "10.#{subnet + 3}.#{i}.0") }
    end
  end
end

configure :test do
  # Run tests on DB 15
  redis = Redis.new({ :db => 15, :timeout => 1 })
  redis.flushall
  set :redis, redis

  site = 'rennes'
  (0..1).each { |i| redis.rpush(subnets_key(site), "10.#{@subnets[site].first}.#{i}.0") }
end

Thread.new do
  while true
    sleep 60
    settings.session.root.sites.map { |s| s['uid'] }.each do |site|
      jobs = settings.redis.smembers(jobs_key(site))
      jobs.each do |job_id|
        begin
          job = settings.session.root.sites[site.to_sym].jobs[job_id.to_sym].reload
          if job['state'] != 'running'
            job_subnets = settings.redis.smembers(job_key(site, job_id))
            job_subnets.each do |subnet|
              settings.redis.rpush(subnets_key(site), subnet)
            end
            settings.redis.del(job_key(site, job_id))
            settings.redis.srem(jobs_key(site), job_id)
          end
        rescue => e
          puts e
          next
        end
      end
    end
  end
end

error 403 do
  "Access forbidden because the job you provided is not running\n"
end

post '/sites/:site/jobs/:job_id/subnets' do |site, job_id|
 begin
    job = settings.session.root.sites[site.to_sym].jobs[job_id.to_sym]
    return 403 if job['state'] != 'running'
  rescue Restfully::HTTP::Error
    return 500
  end

  subnet = settings.redis.lpop(subnets_key(site))
  if subnet
    settings.redis.sadd(job_key(site, job_id), subnet)
    settings.redis.sadd(jobs_key(site), job_id)
    return subnet + "\n"
  else
    return 404
  end
end

# This frees all subnets allocated to the job
delete '/sites/:site/jobs/:job_id/subnets' do |site, job_id|
  subnets = settings.redis.smembers(job_key(site, job_id))
  subnets.each do |subnet|
    settings.redis.srem(job_key(site, job_id), subnet)
    settings.redis.rpush(subnets_key(site), subnet)
  end
  settings.redis.srem(jobs_key(site), job_id)
  settings.redis.del(job_key(site, job_id))
  return 204
end

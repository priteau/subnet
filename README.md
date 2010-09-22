Grid'5000 subnet reservation
============================

This is a small Sinatra web service allowing to reserve subnets on Grid'5000 in
the IP range dedicated to virtualization usage.

User interface
--------------

A RESTful API is available to do a reservation of a /24 subnet. Subnet
reservations must be associated with a job in the *running* state.

To get a new subnet associated with the job 123456 in Rennes, do a HTTP POST request at the following URL:

    /sites/rennes/jobs/123456/subnets

If a subnet is available, the response has a status code of 200, and the body
contains the name of the subnet, followed by a LF symbol (to ease use of the
result from shell scripts). The above POST request would give a result such as:

    10.156.0.0

When all subnets are reserved, the response has a status code of 404.

Each subnet reservation creates a new HTTP resource, that can be retrieved with
a GET at an URL like this:

    /sites/rennes/jobs/123456/subnets/10.156.0.0

This returns a list of all IPs in the subnet, ended by a new line.

Reservations are automatically removed when a job is terminated.
However, it is also possible to remove reservations manually with a DELETE
request. In the previous example, send a HTTP DELETE request at the following URL:

    /sites/rennes/jobs/123456/subnets

Examples
--------

### cURL

    $ SITE='rennes'
    $ JOB='123456'
    $ SUBNET=`curl -f -d '' -f http://localhost:9292/sites/$SITE/jobs/$JOB/subnets` # Reserves a subnet
    $ curl -f http://localhost:9292/sites/$SITE/jobs/$JOB/subnets/$SUBNET # Gets all IPs
    10.156.0.1
    10.156.0.2

    [...]

    10.156.0.253
    10.156.0.254
    $ curl -X DELETE -f http://localhost:9292/sites/$SITE/jobs/$JOB/subnets # Cancels the reservation

### Ruby REST Client

    site = 'rennes'
    job = 123456
    base_ip = RestClient.post "http://localhost:9292/sites/#{site}/jobs/#{job}/subnets", {} # Reserves a subnet
    base_ip.chomp! # To remove the new line at the end
    RestClient.get "http://localhost:9292/sites/#{site}/jobs/#{job}/subnets/#{base_ip}" # Gets all IPs
    RestClient.delete "http://localhost:9292/sites/#{site}/jobs/#{job}/subnets" # Cancels the reservation

Deployment notes
----------------

The dependencies of this service are described using Bundler
(http://gembundler.com/).

First, install Bundler:

    $ gem install bundler

Then, install the dependencies

    $ bundle install

This service depends on a Redis server running on localhost:6379 (tested with
version 2.0.1):

    $ redis-server

Finally, start the service:

    $ rackup

TODO
----

* Allow to specify the Redis server address (probably in config.ru)
* Add an authentification layer (ident/basic auth) to make sure subnet
reservation is associated with a job owned by the user

##crowdring
==============

+ Crowdring, originally from https://github.com/mbelinsky/Crowdring

+ Pre Install
  
  + Install Redis
  
      + download redit from [Here](http://redis.io/)

      + run `tar xvf redis.version.tar`

      + `cd redis.version/`

      + run `make install`
  
  + Install Ruby 1.9.3
  
  + Install database 
      
      + defaults to PostgreSQL ie. postgres://localhost/crowdring_#{ENVIRONMENT}

+ To Install. 

  + `git clone git@github.com:nherzing/crowdring.git`

  + `cd crowdring`

  + `bundle install`
  
  + `rake db:reset` 
  

+ To Run
  
  + `foreman start -f Procfile.dev`

  + Sign in as frodo@crowdring.org, password `gAnd0lf`
  
+ Supported Services
  
  + Plivo, Twilio, Tropo, KooKoo, Voxeo, Nexmo, Routo, Netcore.
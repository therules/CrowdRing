##crowdring
==============
+ Authored by: Nathan Herzing and Willa Wang. Lead: Manu Kabahizi. CopyLeft: The Rules

+ Crowdring, originally from https://github.com/mbelinsky/Crowdring

+ Pre Install
  
  + Install Redis
  
      + download redis from [Here](http://redis.io/)

      + run `tar xvf redis.version.tar`

      + `cd redis.version/`

      + run `make install`
  
  + Install Ruby 1.9.3
  
  + Install database 
      
      + defaults to PostgreSQL ie. postgres://localhost/crowdring_#{ENVIRONMENT}

      + create database `crowdring_development`, `crowdring_test`, `crowdring_production` locally.

+ To Install. 

  + `git clone git@github.com:therules/CrowdRing.git`

  + `cd crowdring`

  + `bundle`
  
  + `rake db:migrate`
  

+ To Run
  
  + `foreman start -f Procfile.dev`

  + Sign in as frodo@crowdring.org, password `gAnd0lf`
  
+ Supported Services
  
  + Plivo, Twilio, Tropo, KooKoo, Voxeo, Nexmo, Routo, Netcore.

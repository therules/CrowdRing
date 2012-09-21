$LOAD_PATH.unshift 'lib'
require 'crowdring'
require 'resque/tasks'

namespace :db do 
  task :reset do
    require 'data_mapper'
    require 'crowdring/campaign'
    require 'crowdring/supporter'

    database_url = ENV["DATABASE_URL"] || 'postgres://localhost/crowdring'
    DataMapper.setup(:default, database_url)
    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end

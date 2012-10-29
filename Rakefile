$LOAD_PATH.unshift 'lib'

require 'resque/tasks'

task :environment, :env do |cmd, args|
  ENV["RACK_ENV"] ||= args[:env] || "development"
  require 'crowdring'
end


namespace :db do 
  task :migrate, :env do |cmd, args|
    env = args[:env] || "development"
    Rake::Task['environment'].invoke(env)

    database_url = ENV["DATABASE_URL"] || "postgres://localhost/crowdring_#{env}"
    DataMapper.setup(:default, database_url)
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end

  task :reset, :env do |cmd, args|
    env = args[:env] || "development"
    Rake::Task['environment'].invoke(env)

    database_url = ENV["DATABASE_URL"] || "postgres://localhost/crowdring_#{env}"
    DataMapper.setup(:default, database_url)
    DataMapper.finalize
    DataMapper.auto_migrate!

    User.set(
      email: ENV["ADMIN_EMAIL"] || 'nherzing@gmail.com',
      password: ENV["ADMIN_PASSWORD"] || 'password',
      password_confirmation: ENV["ADMIN_PASSWORD"] || 'password')
  end
end

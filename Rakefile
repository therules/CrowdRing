$LOAD_PATH.unshift 'lib'
require 'rake'
require 'resque/tasks'

task :environment, :env do |cmd, args|
  ENV["RACK_ENV"] ||= args[:env] || "development"
  require 'crowdring'
end


namespace :db do 
  desc "Create database, env symbol are in [development, test, production]."
  task :migrate, :env do |cmd, args|
    env = args[:env] || "development"
    Rake::Task['environment'].invoke(env)

    DataMapper.repository.auto_migrate!
  end

  task :update, :env do |cmd, args|
    env = args[:env] || "development"
    Rake::Task['environment'].invoke(env)

    DataMapper.repository.auto_upgrade!

    User.set(
      email: ENV["ADMIN_EMAIL"] || 'frodo@crowdring.org',
      password: ENV["ADMIN_PASSWORD"] || 'gAnd0lf',
      password_confirmation: ENV["ADMIN_PASSWORD"] || 'gAnd0lf')
  end
end

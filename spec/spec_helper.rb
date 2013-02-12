require 'rubygems'
require 'bundler/setup'

require 'mongoid'
require 'mongoid/verbalize'

require 'rspec'

Mongoid.configure do |config|
  config.connect_to('mongoid_verbalize_test')
end
# Mongoid.logger = Logger.new($stdout)
# Mongoid.logger.level = Logger::DEBUG
# Moped.logger.level = Logger::DEBUG
# Moped.logger = Logger.new($stdout)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.after(:each) { Mongoid.purge! }
end
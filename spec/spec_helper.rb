require 'rubygems'
require 'bundler/setup'

require 'mongoid'
require 'mongoid/verbalize'

require 'rspec'

Mongoid.configure do |config|
	config.master = Mongo::Connection.new.db('mongoid_verbalize_test')
	config.allow_dynamic_fields = false
  #config.connect_to('mongoid_verbalize_test')
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.after(:each) { Mongoid.purge! }
end
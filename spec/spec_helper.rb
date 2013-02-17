MODELS = File.join(File.dirname(__FILE__), "app/models")
$LOAD_PATH.unshift(MODELS)

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

# Set the database that the spec suite connects to.
RSpec.configure do |config|
  config.mock_with :rspec
  config.after(:each) { Mongoid.purge! }
end

# Autoload every model for the test suite that sits in spec/app/models.
Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end
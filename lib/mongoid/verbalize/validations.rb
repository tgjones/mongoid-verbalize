require 'mongoid/verbalize/validations/macros'
require 'mongoid/verbalize/validations/default_locale_presence'

module Mongoid
	module Verbalize
		module Validations
			extend ActiveSupport::Concern

			included do
				include Macros
			end
		end
	end
end
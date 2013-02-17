require 'mongoid/verbalize/validations/macros'
require 'mongoid/verbalize/validations/default_locale_presence'

module Mongoid
	module Verbalize
		module Validations
			extend ActiveSupport::Concern

			included do
				include Macros
			end

			def read_attribute_for_validation(attr)
				attribute = attr.to_s
				if fields[attribute].try(:type) == Mongoid::Verbalize::TranslatedString
					attributes[attribute]
				else
					super
				end
			end
		end
	end
end
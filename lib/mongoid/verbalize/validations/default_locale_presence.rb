module Mongoid
	module Verbalize
		module Validations
			class DefaultLocalePresenceValidator < ActiveModel::EachValidator
				def validate_each(document, attribute, value)
          if value.nil? || value.value_for_locale([::I18n.default_locale]).blank?
            document.errors.add(attribute, :blank, options)
          end
				end
			end
		end
	end
end
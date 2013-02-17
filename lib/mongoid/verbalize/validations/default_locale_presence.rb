module Mongoid
	module Verbalize
		module Validations
			class DefaultLocalePresenceValidator < ActiveModel::EachValidator
				def validate_each(document, attribute, value)
					field = document.fields[attribute.to_s]
					translations = field.demongoize(value)
          if translations.nil? || translations.value_for_locale([::I18n.default_locale]).blank?
            document.errors.add(attribute, :blank, options)
          end
				end
			end
		end
	end
end
module Mongoid
	module Verbalize
		module Validations
			module Macros
				def validates_default_locale(*args)
	        validates_with(DefaultLocalePresenceValidator, _merge_attributes(args))
	      end
	    end
    end
  end
end
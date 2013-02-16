require 'mongoid/verbalize/fields'
require 'mongoid/verbalize/translated_string'
require 'mongoid/verbalize/selector'
require 'mongoid/verbalize/verbalized_validator'
require 'mongoid/verbalize/verbalized_version'
require 'mongoid/verbalize/versioning'

module Mongoid
  module Verbalize
    extend ActiveSupport::Concern
    
    included do
      include Mongoid::Verbalize::Fields

      Mongoid::Fields.option :use_default_if_empty do |model, field, value| end
    end
  
    module ClassMethods
      def verbalized_field(name, options = {})
        field(name, options.merge(:type => TranslatedString, :default => {}))
      end

      def validates_default_locale(names, options = {})
        validates_with VerbalizedValidator, options.merge(:mode => :only_default, :attributes => names)
      end

      def validates_one_locale(names, options = {})
        validates_with VerbalizedValidator, options.merge(:mode => :one_locale,   :attributes => names)
      end

      def validates_all_locales(names, options = {})
        validates_with VerbalizedValidator, options.merge(:mode => :all_locales,  :attributes => names)
      end
    end
  end
end
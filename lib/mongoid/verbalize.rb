require 'mongoid/verbalize/fields'
require 'mongoid/verbalize/translated_string'
require 'mongoid/verbalize/selector'
require 'mongoid/verbalize/validations'
require 'mongoid/verbalize/verbalized_version'
require 'mongoid/verbalize/versioning'

module Mongoid
  module Verbalize
    extend ActiveSupport::Concern
    
    included do
      include Mongoid::Verbalize::Fields
      include Mongoid::Verbalize::Validations

      Mongoid::Fields.option :use_default_if_empty do |model, field, value| end
    end
  end
end
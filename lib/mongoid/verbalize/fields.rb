module Mongoid
  module Verbalize
    module Fields
      extend ActiveSupport::Concern

      module ClassMethods

      protected

        # Monkey patch for Mongoid method
        def create_accessors(name, meth, options = {})
          # Let Mongoid do its thing
          super

          return unless options[:type] == Mongoid::Verbalize::TranslatedString

          field = fields[name]

          create_verbalized_field_getter(name, meth, field)
          create_verbalized_field_setter(name, meth, field)
          
          create_verbalized_translations_getter(name, meth, field)
          create_verbalized_translations_setter(name, meth, field)

          create_verbalized_translations_raw_getter(name, meth)
          create_verbalized_translations_raw_setter(name, meth)
        end

        def create_verbalized_field_getter(name, meth, field)
          generated_methods.module_eval do
            define_method("#{meth}") do
              raw = read_attribute(name)
              field_value = field.demongoize(raw)
              field_value.current_locale_value(field.options[:use_default_if_empty])
            end
          end
        end

        def create_verbalized_field_setter(name, meth, field)
          generated_methods.module_eval do
            define_method("#{meth}=") do |value|
              raw = read_attribute(name)
              field_value = field.demongoize(raw)
              field_value.current_locale_value = value
              write_attribute(name, field_value)
            end
          end
        end

        def create_verbalized_translations_getter(name, meth, field)
          generated_methods.module_eval do
            define_method("#{meth}_translations") do
              field.demongoize(read_attribute(name))
            end
          end
        end

        def create_verbalized_translations_setter(name, meth, field)
          generated_methods.module_eval do
            define_method("#{meth}_translations=") do |value|
              write_attribute(name, field.mongoize(value))
            end
          end
        end

        def create_verbalized_translations_raw_getter(name, meth)
          generated_methods.module_eval do
            define_method("#{meth}_translations_raw") do
              read_attribute(name)
            end
          end
        end

        def create_verbalized_translations_raw_setter(name, meth)
          generated_methods.module_eval do
            define_method("#{meth}_translations_raw=") do |values|
              write_attribute(name, values)
            end
          end
        end
      end
    end
  end
end
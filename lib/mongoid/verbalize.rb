require 'mongoid/verbalize/verbalized_field'
require 'mongoid/verbalize/criterion/selector'
require 'mongoid/verbalize/verbalized_validator'
require 'mongoid/verbalize/verbalized_version'

module Mongoid
  module Verbalize
    extend ActiveSupport::Concern
    
    included do
      include ActiveSupport::Callbacks

      Mongoid::Fields.option :use_default_if_empty do |model, field, value|
        # TODO
      end
    end
    
    def create_new_version
      return if embedded? # Only do this on the root document

      # Do a first pass to see if any verbalized field has changed
      any_field_changed = false
      iterate_all_verbalized_fields do |document, field|
        any_field_changed = true if field.demongoize(document.read_attribute(field.name)).changed?
      end
      return unless any_field_changed

      run_callbacks :create_version do
        # Calculate new version number
        previous_version = self.verbalized_versions.last.version if self.verbalized_versions.last.present?
        next_version_number = previous_version.present? ? previous_version + 1 : 0
        self.verbalized_versions.build(:version => next_version_number)
      
        # Apply this new version number to verbalized fields
        iterate_all_verbalized_fields do |document, field|
          field_value = field.demongoize(document.read_attribute(field.name))
          field_value.prepare_for_save(next_version_number)
          document.write_attribute(field.name, field_value)
        end
      end

      # Reset _children so that Mongoid persists verbalized_versions correctly
      @_children = nil
    end
    
    def all_verbalized_field_values
      [self.class.verbalized_field_values(self) + self.class.verbalized_children(self).map do |child|
        self.class.verbalized_field_values(child)
      end].flatten
    end
    
    def iterate_all_verbalized_fields(&block)
      self.class.iterate_verbalized_fields(self, &block)
      self.class.verbalized_children(self).each do |child|
        self.class.iterate_verbalized_fields(child, &block)
      end
    end
    
    def current_version
      self.verbalized_versions.last.version
    end
  
    module ClassMethods
      def acts_as_verbalized_document
        define_callbacks :create_version
        embeds_many :verbalized_versions, :as => :versionable,
          :class_name => 'Mongoid::Verbalize::VerbalizedVersion'
        before_save :create_new_version
      end
      
      def verbalized_field(name, options = {})
        field(name, options.merge(:type => VerbalizedField, :default => {}))
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
      
      def verbalized_fields(document)
        document.class.fields.reject { |name, field| field.options[:type] != VerbalizedField }
      end
      
      def verbalized_children(document)
        document._children.reject { |child| !child.class.include?(Mongoid::Verbalize) }
      end
      
      def verbalized_field_values(document)
        verbalized_fields(document).map do |name, field|
          document.send("#{field.name}_translations")
        end
      end
      
      def iterate_verbalized_fields(document, &block)
        verbalized_fields(document).each do |name, field|
          yield document, field
        end
      end

    protected
      def create_accessors(name, meth, options = {})
        # Let Mongoid do all stuff
        super

        # Skip if create_accessors called on non LocalizedField field
        return if VerbalizedField != options[:type]

        # Get field to retain incapsulation of LocalizedField class
        field = fields[name]
        
        create_verbalized_field_getter(name, meth, field)
        create_verbalized_field_setter(name, meth, field)
        
        create_verbalized_translations_getter(name, meth, field)

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
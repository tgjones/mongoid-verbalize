module Mongoid
  module Verbalize
    class VerbalizedField
      include Mongoid::Fields::Serializable
      
      def display_name(document)
        if options[:display_name].is_a? Proc
          options[:display_name].call(document)
        else
          options[:display_name]
        end
      end
      
      def path(document)
        if options[:path].present? && options[:path].is_a?(Proc)
          options[:path].call(document)
        else
          options[:path] || name
        end
      end

      # Return translated values of field, accoring to current locale.
      # If :use_default_if_empty is set, then in case when there no
      # translation available for current locale, if will try to
      # get translation for defalt_locale.
      def deserialize(object)
        lookups = [self.locale]

        # TODO: Add I18n.fallbacks support instead of :use_default_if_empty
        if options[:use_default_if_empty]
          lookups.push ::I18n.default_locale.to_s
        end
        
        # Find first localized version array in lookup path
        locale_value = object[lookups.find{|locale| object[locale]}]
        return nil if locale_value.nil?
        
        # Return latest version
        return locale_value["value"]
      end

      # Assing new translation to translation table.
      def assign(object = {}, value)
        locale_value = object[locale] || {}
        object.merge(locale => locale_value.merge("value" => value))
      end

      # Return current locale as string
      def locale
        ::I18n.locale.to_s
      end
      
      def changed?(object)
        iterate_changes(object) do |versions, new_value|
          return true
        end
        false
      end
      
      # Creates a new version for changed values
      def prepare_for_save(object, new_version_number)
        iterate_changes(object) do |versions, new_value|
          versions.push({ "version" => new_version_number, "value" => new_value })
        end
        return object
      end
      
    private
      def iterate_changes(object, &block)
        return if object.nil?
        object.each do |locale, locale_value|
          current_value = locale_value["value"]
          versions = (locale_value["versions"] ||= [])
          previous_version = versions.last
          
          # Has value been changed?
          if previous_version.nil? || previous_version["value"] != current_value
            yield versions, current_value
          end
        end
      end
    end
  end
end
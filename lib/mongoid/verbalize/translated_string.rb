module Mongoid
  module Verbalize
    # Strongly-typed accessor for this structure:
    # {
    #   'en' => { "value" => "Title",  "versions" => [ { "version" => 0, "value" => 'Title' } ] },
    #   'es' => { "value" => "Título", "versions" => [ { "version" => 0, "value" => 'Título' } ] },
    # }
    class TranslatedString
      class LocalizedValue
        attr_accessor :current_value, :versions

        def initialize(current_value=nil, versions=[])
          @current_value = current_value
          @versions = versions
        end

        def changed?
          previous_version = versions.last
          previous_version.nil? || previous_version.value != current_value
        end

        def add_version(new_version_number)
          versions.push(LocalizedVersion.new(new_version_number, current_value))
        end
      end

      LocalizedVersion = Struct.new(:version, :value)

      attr_reader :localized_values

      def initialize(localized_values)
        @localized_values = localized_values
      end

      # Return translated value of field, accoring to current locale.
      # If :use_default_if_empty is set, then in case when there no
      # translation available for current locale, if will try to
      # get translation for defalt_locale.
      def current_locale_value(use_default_if_empty)
        lookups = [self.class.current_locale]

        # TODO: Add I18n.fallbacks support instead of :use_default_if_empty
        if use_default_if_empty
          lookups.push(::I18n.default_locale)
        end
        
        # Find first localized value in lookup path
        localized_value = @localized_values[lookups.find { |l| @localized_values[l] }]
        return nil if localized_value.nil?

        localized_value.current_value
      end
      def current_locale_value=(value)
        current_value.current_value = value
      end

      # Called when determining whether to create a new version.
      def changed?
        @localized_values.values.any?(&:changed?)
      end

      # Creates a new version for changed values
      def prepare_for_save(new_version_number)
        @localized_values.values.select(&:changed?).each do |v|
          v.add_version(new_version_number)
        end
      end

      # Converts an object of this instance into a database friendly value.
      def mongoize
        @localized_values.each_with_object({}) do |(key, value), h|
          h[key.to_s] = {
            'value' => value.current_value,
            'versions' => value.versions.map do |v|
              { 'version' => v.version, 'value' => v.value }
            end
          }
        end
      end

      class << self
        # Get the object as it was stored in the database, and instantiate
        # this custom class from it.
        def demongoize(object)
          localized_values = object.each_with_object({}) do |(key, value), h|
            versions = (value['versions'] || []).map do |v|
              LocalizedVersion.new(v['version'], v['value'])
            end
            h[key.to_sym] = LocalizedValue.new(value['value'], versions)
          end
          TranslatedString.new(localized_values)
        end

        # Takes any possible object and converts it to how it would be
        # stored in the database.
        def mongoize(object)
          case object
          when TranslatedString then object.mongoize
          else object
          end
        end

        # Converts the object that was supplied to a criteria and converts it
        # into a database friendly form.
        def evolve(object)
          case object
          when TranslatedString then object.mongoize.current_locale_value
          else object
          end
        end

        # Return current locale as string
        def current_locale
          ::I18n.locale
        end
      end

    private

      # TODO: Rename this method.
      def current_value
        @localized_values[self.class.current_locale] ||= LocalizedValue.new
      end
    end
  end
end
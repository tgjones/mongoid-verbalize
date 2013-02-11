module Mongoid
  module Verbalize
    # Strongly-typed accessor for this structure:
    # {
    #   'en' => { "value" => "Title",  "versions" => [ { "version" => 0, "value" => 'Title' } ] },
    #   'es' => { "value" => "Título", "versions" => [ { "version" => 0, "value" => 'Título' } ] },
    # }
    # When any changes are made, it immediately updates the parent document
    class VerbalizedFieldValue
      attr_reader :name
      attr_reader :display_name
      attr_reader :path
      
      def initialize(document, name, display_name, path, hash)
        @document, @name, @display_name, @path = document, name, display_name, path
        @localized_values = {}
        hash.each do |key, value|
          @localized_values[key.to_sym] = VerbalizedFieldLocalizedValue.new(self, value)
        end
      end
      
      def [](language)
        @localized_values[language]
      end
      
      def find_version(language, version)
        localized_value = @localized_values[language]
        return unless localized_value.present?
        
        localized_value.find_version(version)
      end
      
      def append(language, version, value)
        @localized_values[language] ||= VerbalizedFieldLocalizedValue.new(self)
        @localized_values[language].append(version, value)
      end
      
      def update_document
        @document.write_attribute(@name, to_hash)
      end
      
    private
    
      def to_hash
        result = {}
        @localized_values.each do |key, value|
          result[key.to_s] = value.to_hash
        end
        result
      end
    end
    
    class VerbalizedFieldLocalizedValue
      attr_reader :current_value, :versions
      
      def current_value=(value)
        @current_value = value
        @parent.update_document
      end
      
      def initialize(parent, hash={})
        @parent = parent
        
        @current_value = hash['value']
        @versions = if hash['versions'].present? then
          hash['versions'].map do |v|
            VerbalizedFieldLocalizedValueVersion.new(parent, v['version'], v['value'])
          end
        else
          []
        end
      end

      def find_version(version)
        versions.find_all { |v| v.version <= version }.last
      end
      
      def append(version, value)
        @current_value = value
        @versions << VerbalizedFieldLocalizedValueVersion.new(@parent, version, value)
        @parent.update_document
      end
      
      def to_hash
        {
          "value" => current_value,
          "versions" => versions.map do |v|
            { "version" => v.version, "value" => v.value }
          end
        }
      end
    end
    
    class VerbalizedFieldLocalizedValueVersion
      attr_reader :version, :value
      
      def version=(value)
        @version = value
        @parent.update_document
      end
      
      def value=(value)
        @value = value
        @parent.update_document
      end
      
      def initialize(parent, version, value)
        @parent = parent
        @version = version
        @value = value
      end
    end
  end
end
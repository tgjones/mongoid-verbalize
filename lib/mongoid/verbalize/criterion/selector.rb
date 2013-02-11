module Mongoid
  module Criterion
    class Selector< Hash
      def []=(key, value)
        if fields[key.to_s].try(:type) == Mongoid::Verbalize::VerbalizedField
          key = "#{key}.#{::I18n.locale}.value"
        end
        super
      end
    end
  end
end
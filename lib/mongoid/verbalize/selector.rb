module Origin
  class Selector
  
  private

    def normalized_key(key, serializer)
      if serializer && serializer.type == Mongoid::Verbalize::TranslatedString
        "#{key}.#{::I18n.locale}.value"
      else
        super
      end
    end
  end
end
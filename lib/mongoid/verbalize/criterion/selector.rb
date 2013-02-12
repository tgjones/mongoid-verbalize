module Origin
  class Selector
  
  private

    def normalized_key(key, serializer)
      if serializer.type == Mongoid::Verbalize::VerbalizedField
        "#{key}.#{::I18n.locale}.value"
      else
        super
      end
    end
  end
end
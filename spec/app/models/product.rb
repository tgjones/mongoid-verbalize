class Product
	include Mongoid::Document
	include Mongoid::Verbalize
	include Mongoid::Verbalize::Versioning

	verbalized_field :name

	validates :name, default_locale_presence: true
end
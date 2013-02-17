require 'spec_helper'

describe Mongoid::Verbalize::Validations::DefaultLocalePresenceValidator do
	describe '#validate_each' do
		let(:product)    { Product.new }
		let(:name_field) { product.fields['name'] }
		let(:validator)  { described_class.new(attributes: product.attributes) }

		context 'when the value is valid' do
			before { validator.validate_each(product, :name, name_field.demongoize({ 'en' => { 'value' => 'Foo' } })) }

			it 'adds no errors' do
				puts product.errors[:name]
				product.errors[:name].should be_empty
			end
		end

		context 'when the value is nil' do
			before { validator.validate_each(product, :name, nil) }

			it 'adds errors' do
				product.errors[:name].should eq(["can't be blank"])
			end
		end
	end
end
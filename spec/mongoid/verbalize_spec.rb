# encoding: utf-8
require 'spec_helper'

class Entry
  include Mongoid::Document
  include Mongoid::Verbalize
  include Mongoid::Verbalize::Versioning

  field :weight, :type => Integer, :default => 60

  verbalized_field :title
  verbalized_field :title_with_default, :use_default_if_empty => true
end

describe Mongoid::Verbalize, "verbalized_field" do
  before do
    I18n.locale = :en
  end

  describe "without an assigned value" do
    before do
      @entry = Entry.new
    end

    it "should return blank" do
      @entry.title.should be_blank
    end
  end

  describe "with an assigned value" do
    before do
      @entry = Entry.new(:title => 'Title')
    end

    it "should return that value" do
      @entry.title.should == 'Title'
    end

    describe "and persisted" do
      before do
        @entry.save
      end

      describe "find by id" do
        it "should find the document" do
          Entry.find(@entry.id).should == @entry
        end
      end

      describe "where() criteria" do
        it "should use the current locale value" do
          query = Entry.where(:title => 'Title')
          Entry.where(:title => 'Title').first.should == @entry
        end
      end
    end

    describe "when the locale is changed" do
      before do
        I18n.locale = :es
      end

      it "should return a blank value" do
        @entry.title.should be_blank
      end

      describe "a new value is assigned" do
        before do
          @entry.title = 'Título'
        end

        it "should return the new value" do
          @entry.title.should == 'Título'
        end

        describe "persisted and retrieved from db" do
          before do
            @entry.save
            @entry.reload
          end

          it "the localized field value should be correct" do
            @entry.title.should == 'Título'
            I18n.locale = :en
            @entry.title.should == 'Title'
            @entry.title_translations_raw.should == {
              'en' => { "value" => "Title",  "versions" => [ { "version" => 0, "value" => 'Title' } ] },
              'es' => { "value" => "Título", "versions" => [ { "version" => 0, "value" => 'Título' } ] },
            }
            @entry.verbalized_versions.should have(1).item
          end
        end

        describe "field translations hash" do
          context "before saving" do
            it "should return all translations without versions" do
              @entry.title_translations_raw.should == {
                'en' => { "value" => "Title", "versions" => [] },
                'es' => { "value" => "Título", "versions" => [] },
              }
            end
          end
          
          context "after saving" do
            before do
              @entry.save
              @entry.reload
            end

            it "should return all translations with versions" do
              @entry.title_translations_raw.should == {
                'en' => { "value" => "Title",  "versions" => [ { "version" => 0, "value" => 'Title' } ] },
                'es' => { "value" => "Título", "versions" => [ { "version" => 0, "value" => 'Título' } ] },
              }
            end
          end
        end
        
        describe "field translations" do
          context "before saving" do
            it "should return all translations without versions" do
              @entry.title_translations.should be_instance_of(
                Mongoid::Verbalize::TranslatedString)
              @entry.title_translations.localized_values[:en].should be_instance_of(
                Mongoid::Verbalize::TranslatedString::LocalizedValue)
              @entry.title_translations.localized_values[:en].current_value.should == 'Title'
              @entry.title_translations.localized_values[:en].versions.should == []
              @entry.title_translations.localized_values[:es].should be_instance_of(
                Mongoid::Verbalize::TranslatedString::LocalizedValue)
              @entry.title_translations.localized_values[:es].current_value.should == 'Título'
              @entry.title_translations.localized_values[:es].versions.should == []
            end
          end
          
          context "after saving" do
            before do
              @entry.save
              @entry.reload
            end

            it "should return all translations with versions" do
              @entry.title_translations.localized_values[:en].should be_instance_of(
                Mongoid::Verbalize::TranslatedString::LocalizedValue)
              @entry.title_translations.localized_values[:en].current_value.should == 'Title'
              @entry.title_translations.localized_values[:en].versions.should have(1).item
              @entry.title_translations.localized_values[:en].versions[0].should be_instance_of(
                Mongoid::Verbalize::TranslatedString::LocalizedVersion)
              @entry.title_translations.localized_values[:en].versions[0].version.should == 0
              @entry.title_translations.localized_values[:en].versions[0].value.should == 'Title'
              @entry.title_translations.localized_values[:es].should be_instance_of(
                Mongoid::Verbalize::TranslatedString::LocalizedValue)
              @entry.title_translations.localized_values[:es].current_value.should == 'Título'
              @entry.title_translations.localized_values[:es].versions.should have(1).item
              @entry.title_translations.localized_values[:es].versions[0].should be_instance_of(
                Mongoid::Verbalize::TranslatedString::LocalizedVersion)
              @entry.title_translations.localized_values[:es].versions[0].version.should == 0
              @entry.title_translations.localized_values[:es].versions[0].value.should == 'Título'
            end
          end
        end

        describe "with mass-assigned translations" do
          before do
            @entry.title_translations_raw = {
              'en' => { "value" => "Title",  "versions" => [ { "version" => 0, "value" => 'Title' } ] },
              'es' => { "value" => "Nuevo título", "versions" => [ { "version" => 0, "value" => 'Nuevo título' } ] },
            }
          end

          it "should set all translations" do
            @entry.title_translations_raw.should == {
              'en' => { "value" => "Title",  "versions" => [ { "version" => 0, "value" => 'Title' } ] },
              'es' => { "value" => "Nuevo título", "versions" => [ { "version" => 0, "value" => 'Nuevo título' } ] },
            }
          end

          it "the getter should return the new translation" do
            @entry.title.should == 'Nuevo título'
          end
        end

        describe "if we go back to the original locale" do
          before do
            I18n.locale = :en
          end

          it "should return the original value" do
            @entry.title.should == 'Title'
          end
        end
      end
    end
  end
end

describe Mongoid::Verbalize do
  before do
    I18n.locale = :en
  end
  
  describe "versions" do
    before { @entry = Entry.new }
    subject { @entry }
    
    describe "document versions" do
      before do
        @entry.title = 'foo'
        @entry.save
      end
      
      its(:verbalized_versions) { should have(1).item }
    end
    
    describe "when field is updated twice without saving" do
      before do
        @entry.title = 'foo'
        @entry.title = 'bar'
        @expected_translations = {
          'en' => { "value" => 'bar', 'versions' => [] }
        }
      end
      
      its(:title_translations_raw) { should == @expected_translations }
    end
    
    describe "when field is not updated" do
      before do
        @entry.title = 'foo'
        @entry.title_with_default = 'bar'
        I18n.locale = :es
        @entry.title = 'spanishfoo'
        I18n.locale = :en
        @entry.save
        @entry.title = 'baz'
        @entry.save
        @expected_title_translations = {
          'en' => {
            "value" => "baz",
            "versions" => [
              { "version" => 0, "value" => 'foo' },
              { "version" => 1, "value" => 'baz' }
            ]
          },
          'es' => {
            "value" => "spanishfoo",
            "versions" => [
              { "version" => 0, "value" => 'spanishfoo' }
            ]
          }
        }
        @expected_title_with_default_translations = {
          'en' => {
            "value" => "bar",
            "versions" => [
              { "version" => 0, "value" => 'bar' }
            ]
          }
        }
      end
      
      its(:title_translations_raw) { should == @expected_title_translations }
      its(:title_with_default_translations_raw) { should == @expected_title_with_default_translations }
    end
    
    describe "when field is updated, saved, updated, and then saved" do
      before do
        @entry.title = 'foo'
        @entry.save
        @entry.title = 'bar'
        @entry.save
        @expected_translations = {
          'en' => {
            "value" => "bar",
            "versions" => [
              { "version" => 0, "value" => 'foo' },
              { "version" => 1, "value" => 'bar' }
            ]
          }
        }
      end
      
      its(:title_translations_raw) { should == @expected_translations }
    end
    
    describe "when field is updated with the same value" do
      before do
        @entry.title = 'foo'
        @entry.save
        @entry.title = 'foo'
        @entry.save
        @expected_translations = {
          'en' => {
            "value" => "foo",
            "versions" => [
              { "version" => 0, "value" => 'foo' }
            ]
          }
        }
      end
      
      its(:title_translations_raw) { should == @expected_translations }
      its(:verbalized_versions) { should have(1).item }
    end
    
    describe "embedded document" do
      before do
        class Entry
          include Mongoid::Document
          include Mongoid::Verbalize
          include Mongoid::Verbalize::Versioning
          
          verbalized_field :title
          embeds_many :sub_entries
        end

        class SubEntry
          include Mongoid::Document
          include Mongoid::Verbalize
          verbalized_field :subtitle
          embedded_in :entry
        end
        @entry = Entry.new(:title => 'Selfridges')
        @sub_entry = @entry.sub_entries.build(:subtitle => 'Oxford Street')
        @entry.save
        @entry.save
        @entry.reload
        @sub_entry = @entry.sub_entries.first
        @expected_title_translations = {
          'en' => {
            "value" => "Selfridges",
            "versions" => [
              { "version" => 0, "value" => 'Selfridges' }
            ]
          }
        }
        @expected_subtitle_translations = {
          'en' => {
            "value" => "Oxford Street",
            "versions" => [
              { "version" => 0, "value" => 'Oxford Street' }
            ]
          }
        }
      end
      
      describe "entry" do
        subject { @entry }
        its(:verbalized_versions) { should have(1).item }
        its(:title_translations_raw) { should == @expected_title_translations }
      end
      
      describe "subentry" do
        subject { @sub_entry }
        it { should_not respond_to(:verbalized_versions) }
        its(:subtitle_translations_raw) { should == @expected_subtitle_translations }
      end
      
      describe "when subentry is updated" do
        before do
          @sub_entry.subtitle = 'Regent Street'
          @entry.save
          #@entry.reload
        end
        
        describe "entry" do
          subject { @entry }
          its(:verbalized_versions) { should have(2).items }
          its("verbalized_versions.first.version") { should == 0 }
          its("verbalized_versions.second.version") { should == 1 }
        end
      end
    end
  end
end

describe Mongoid::Verbalize, 'localized field in embedded association' do
  before do
    class Entry
      embeds_many :sub_entries
    end

    class SubEntry
      include Mongoid::Document
      include Mongoid::Verbalize
      verbalized_field :title
      embedded_in :entry, :inverse_of => :sub_entries
    end
    @entry = Entry.new
    @sub_entries = (0..2).map { @entry.sub_entries.build }
  end

  it "should contain the embedded documents" do
    @entry.sub_entries.criteria.instance_variable_get("@documents").should == @sub_entries
  end
end

describe Mongoid::Verbalize, 'localized field in embedded document' do
  before do
    class Entry
      embeds_one :sub_entry
    end

    class SubEntry
      include Mongoid::Document
      include Mongoid::Verbalize
      verbalized_field :subtitle
      embedded_in :entry, :inverse_of => :sub_entries
    end
    @entry = Entry.new
    @entry.create_sub_entry(:subtitle => 'Oxford Street')
  end

  it "should store the title in the right locale" do
    @entry.reload.sub_entry.subtitle.should == 'Oxford Street'
  end
end

describe Mongoid::Verbalize, "verbalized_field with :use_default_if_empty => true" do
  before do
    I18n.default_locale = :en
    I18n.locale = :en
  end

  describe "without an assigned value" do
    before do
      @entry = Entry.new
    end

    it "should return blank" do
      @entry.title_with_default.should be_blank
    end
  end

  describe "with an assigned value in the default locale" do
    before do
      @entry = Entry.new(:title_with_default => 'Title with default')
    end

    it "should return that value with the default locale" do
      @entry.title_with_default.should == 'Title with default'
    end

    describe "when the locale is changed" do
      before do
        I18n.locale = :it
      end

      it "should return the value of the default locale" do
        @entry.title_with_default.should == 'Title with default'
      end

      describe "when a new value is assigned" do
        before do
          @entry.title_with_default = 'Titolo con default'
        end

        it "should return the new value" do
          @entry.title_with_default.should == 'Titolo con default'
        end

        describe "if we go back to the original locale" do
          before do
            I18n.locale = :en
          end

          it "should return the original value" do
            @entry.title_with_default.should == 'Title with default'
          end
        end
      end
    end
  end
end

describe Mongoid::Verbalize, "create_accessors" do
  before do
    I18n.locale = :en
    @entry = Entry.new
  end

  it "should not affect other fields accessors" do
    @entry.weight.should == 60

    @entry.weight = 70
    @entry.weight.should == 70
  end

  it "should not define own methods on for fields" do
    @entry.should_not respond_to :weight_translations
  end
end
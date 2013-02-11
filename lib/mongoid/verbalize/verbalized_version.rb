module Mongoid::Verbalize
  class VerbalizedVersion
    include Mongoid::Document    
    embedded_in :versionable, :polymorphic => true
    field :version, :type => Integer
  end
end
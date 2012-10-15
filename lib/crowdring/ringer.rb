module Crowdring
  class RingerTagging
    include DataMapper::Resource

    belongs_to :ringer, key: true
    belongs_to :tag, key: true
  end


  class Ringer
    include DataMapper::Resource
    include PhoneNumberFields

    property :id,           Serial
    property :phone_number, String, unique: true
    property :created_at,   DateTime

    has n, :ringer_taggings, constraint: :destroy
    has n, :tags, through: :ringer_taggings, constraint: :skip

    has n, :rings, constraint: :destroy
    
    validates_with_method :phone_number, :valid_phone_number?

    after :create, :add_tags

    def add_tags
      tags << Tag.from_str('area code:' + area_code)
      tags << Tag.from_str('country:' + country_name)
      tags.concat(RegionTags.tags_for(number))
      save
    end
  end
end
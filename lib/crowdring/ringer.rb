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
    property :subscribed,  Boolean, default: true

    has n, :ringer_taggings, constraint: :destroy
    has n, :tags, through: :ringer_taggings, constraint: :skip

    has n, :rings, constraint: :destroy
    
    validates_with_method :phone_number, :valid_phone_number?

    after :create, :add_tags

    def self.unsubscribed
      all(subscribed: false)
    end

    def self.subscribed
      all(subscribed: true)
    end

    def phone_number=(number)
      super Phoner::Phone.parse(number).to_s
    end

    def self.from(number)
      norm_number = Phoner::Phone.parse(number).to_s
      self.first(phone_number: norm_number) || self.create(phone_number: norm_number)
    end

    def add_tags
      tags << Tag.from_str('area code:' + area_code)
      tags << Tag.from_str('country:' + country_name)
      tags.concat(Regions.tags_for(number))
      save
    end

    def tag(tag)
      unless tags.include?(tag)
        tags << tag
        save
      end
    end

    def tagged?(tag)
      tags.include?(tag)
    end

    def unsubscribe
      update(subscribed: false)
    end
    
    def subscribe
      update(subscribed: true)
    end

    def subscribed?
      subscribed
    end

    def unsubscribed?
      !subscribed
    end
  end
end
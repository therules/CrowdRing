module Crowdring
  class Voicemail
    include DataMapper::Resource

    property :id, Serial
    property :filename, String, required: false, length: 250

    belongs_to :ringer

    def filename
      super || "ftp://#{ENV['FTP_USER']}:#{ENV['FTP_PASSWORD']}@#{ENV['FTP_HOST']}/voicemails/#{id}.wav"
    end

    def plivo_callback
      "#{ENV['SERVER_NAME']}/voicemails/#{id}/plivo/"
    end
  end
end
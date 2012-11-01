module Crowdring
  class Voicemail
    include DataMapper::Resource

    property :id, Serial

    belongs_to :ringer

    def filename
      "ftp://#{ENV['FTP_USER']}:#{ENV['FTP_PASSWORD']}@#{ENV['FTP_HOST']}/voicemails/#{id}.wav"
    end
  end
end
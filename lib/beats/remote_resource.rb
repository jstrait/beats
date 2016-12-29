require 'httparty'

class RemoteResource
  attr_reader :uri

  def initialize(uri)
    @uri = uri
  end

  def file
    path = "#{Dir.pwd}/#{uri.split('/').last}"
    file = File.open(path, 'wb') do |f| 
      f.write HTTParty.get(uri).parsed_response
      f.close
    end
    return path
  end
end

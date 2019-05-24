require 'net/http'
require 'mail'
require 'json'
require 'pry'
require 'dotenv/load'
Dotenv.load

class Mclass
  attr_reader :data
  def initialize(name)
    @name = name
    @data = nil
  end

  def load_data(url, format:format)
    @data = case format.downcase
    when 'json'
      MjsonLoader.(url)
    when 'xml'
      MxmlLoader.(url)
    else
      MgenericLoader.(url)
    end
  end
end


class MjsonLoader
  def initialize(url)
    @url = url
  end

  def self.call(url)
    new(url).call
  end

  def call
    uri = URI(@url)
    resp = Net::HTTP.get(uri)
    JSON.parse(resp)
  end
end

mc = Mclass
  .new('hot_from_mixcloud')
  .load_data('https://api.mixcloud.com/popular/hot/', format: 'json')

dumped = Marshal.dump(mc)

mail_options = {
  address: ENV['SMTP_HOSTNAME'],
  port: 587,
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'login',
  enable_starttls_auto: true
}


Mail.defaults do
  delivery_method :smtp, mail_options
end

mail = Mail.new do
  to ENV['FROM']
  from ENV['TO'] 
  subject 'Marshaling object'
  body dumped.to_s
end

mail.deliver

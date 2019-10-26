# myapp.rb
require 'sinatra'
require 'freee/api'

CLIENT_ID = ENV.fetch('CLIENT_ID') { '' }
CLIENT_SECRET = ENV.fetch('CLIENT_SECRET') { '' }

# 初期化
OAUTH2 = Freee::Api::Token.new(CLIENT_ID, CLIENT_SECRET)

get '/' do
  'Hello world!'
end

get '/dakoku' do
  'Hello dakuko!'
end

get '/refresh' do
  refresh
end

def refresh
  # 一旦環境変数から取得する
  access_token = ENV.fetch('ACCESS_TOKEN') { '' }
  refresh_token = ENV.fetch('REFRESH_TOKEN') { '' }
  expires_at = ENV.fetch('EXPIRES_AT') { '' }

  pp access_token
  pp refresh_token
  pp expires_at
  response = OAUTH2.refresh_token(access_token, refresh_token, expires_at)
  pp response

  ENV['ACCESS_TOKEN'] = response.token.to_s
  ENV['REFRESH_TOKEN'] = response.refresh_token.to_s
  ENV['EXPIRES_AT'] = response.expires_in.to_s

  File.open("env.sh", "w") do |file|
    file.puts "export ACCESS_TOKEN=#{ENV['ACCESS_TOKEN']} REFRESH_TOKEN=#{ENV['REFRESH_TOKEN']} EXPIRES_AT=#{ENV['EXPIRES_AT']}"
  end

end

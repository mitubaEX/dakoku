# myapp.rb
require 'sinatra'
require 'freee/api'

#################################
# post request util
#################################
require 'net/http'
require 'uri'
require 'json'

def post_for_dakoku(type: '')
  # 一旦環境変数から取得する
  access_token = ENV.fetch('ACCESS_TOKEN') { '' }

  pp access_token
  uri = URI.parse("https://api.freee.co.jp/hr/api/v1/employees/642339/time_clocks")
  body = {
    'company_id' => '1978047',
    'type' => type,
    'base_date' => Date.today.strftime('%Y-%m-%d')
  }
  req_options = {
    use_ssl: uri.scheme == "https"
  }

  # Create the HTTP objects
  req = Net::HTTP::Post.new(uri)
  # header
  req["Authorization"] = "Bearer #{access_token}"
  req["Content-Type"] = "application/json"
  req.body = body.to_json

  # Send the request
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(req)
  end
  pp response.message
  pp response.body

  'hello'
end

def get_for_dakoku_list
  # 一旦環境変数から取得する
  access_token = ENV.fetch('ACCESS_TOKEN') { '' }

  pp access_token
  uri = URI.parse("https://api.freee.co.jp/hr/api/v1/employees/642339/time_clocks")
  req_options = {
    use_ssl: uri.scheme == "https"
  }

  # Create the HTTP objects
  params = {
    :company_id => 1978047,
  }
  uri.query = URI.encode_www_form(params)

  req = Net::HTTP::Get.new(uri)
  # header
  req["Authorization"] = "Bearer #{access_token}"
  req["Content-Type"] = "application/json"

  # Send the request
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(req)
  end
  pp response.message
  pp response.body
  JSON.parse(response.body)
end

#################################
# api
#################################

CLIENT_ID = ENV.fetch('CLIENT_ID') { '' }
CLIENT_SECRET = ENV.fetch('CLIENT_SECRET') { '' }

# 初期化
OAUTH2 = Freee::Api::Token.new(CLIENT_ID, CLIENT_SECRET)

get '/' do
  'Hello world!'
end

get '/dakoku' do
  dakoku
end

get '/refresh' do
  refresh
end

def dakoku
  last_dakoku = get_for_dakoku_list.last
  # 出勤していない場合は、出勤する
  if Date.parse(last_dakoku['date']) == Date.today
    post_for_dakoku(type: 'clock_in')
  end

  # 出勤、退勤を繰り返す
  case last_dakoku['type']
  when 'break_begin'
    post_for_dakoku(type: 'break_end')
  when 'break_end'
    post_for_dakoku(type: 'break_begin')
  end
end

def refresh
  # 一旦環境変数から取得する(dbに移すなど)
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

  # 復活用
  File.open("env.sh", "w") do |file|
    file.puts "export ACCESS_TOKEN=#{ENV['ACCESS_TOKEN']} REFRESH_TOKEN=#{ENV['REFRESH_TOKEN']} EXPIRES_AT=#{ENV['EXPIRES_AT']}"
  end

end

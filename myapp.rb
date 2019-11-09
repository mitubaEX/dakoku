# coding: utf-8
# myapp.rb
require 'sinatra'
require 'freee/api'

set :environment, :production

#################################
# postgres
#################################
require 'pg'

class PgClient
  def initialize
    @connect = PG::connect(host: "db", user: "docker", password: "pass", port: "5432")
  end

  def get_token
    results = @connect.exec("SELECT * from tokens")
    pp results[0]
    return results[0]['access_token'], results[0]['refresh_token'], results[0]['expires_at']
  end

  def update_token(access_token, refresh_token, expires_at)
    @connect.exec("UPDATE tokens SET access_token='#{access_token}', refresh_token='#{refresh_token}', expires_at='#{expires_at}' WHERE id=1")
  end

  def finish
    @connect.finish
  end

end

PG_CLIENT = PgClient.new
# pp PG_CLIENT.get_token

#################################
# post request util
#################################
require 'net/http'
require 'uri'
require 'json'

def post_for_dakoku(type: '')
  # 一旦環境変数から取得する
  # access_token = ENV.fetch('ACCESS_TOKEN') { '' }
  access_token, _, _ = PG_CLIENT.get_token

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

  pp response.body

  # refresh
  if response.code != 200
    refresh
  end

  'hello'
end

def get_for_dakoku_list
  # 一旦環境変数から取得する
  # access_token = ENV.fetch('ACCESS_TOKEN') { '' }
  access_token, _, _ = PG_CLIENT.get_token

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

  # refresh
  if response.code != 200
    refresh
  end

  JSON.parse(response.body)
end

def put_for_dakoku_record(date: '')
  # 一旦環境変数から取得する
  # access_token = ENV.fetch('ACCESS_TOKEN') { '' }
  access_token, _, _ = PG_CLIENT.get_token

  uri = URI.parse("https://api.freee.co.jp/hr/api/v1/employees/642339/work_records/#{date}")
  body = {
    'company_id' => '1978047',
    'break_records' => [],
    'clock_in_at' => "#{date}T09:10:00",
    'clock_out_at' => "#{date}T18:20:00"
  }
  req_options = {
    use_ssl: uri.scheme == "https"
  }

  # Create the HTTP objects
  req = Net::HTTP::Put.new(uri)
  # header
  req["Authorization"] = "Bearer #{access_token}"
  req["Content-Type"] = "application/json"
  req.body = body.to_json

  # Send the request
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(req)
  end

  pp response.body

  # refresh
  refresh
end

def delete_for_dakoku_record(date: '')
  # 一旦環境変数から取得する
  # access_token = ENV.fetch('ACCESS_TOKEN') { '' }
  access_token, _, _ = PG_CLIENT.get_token

  uri = URI.parse("https://api.freee.co.jp/hr/api/v1/employees/642339/work_records/#{date}")
  body = {
    'company_id' => '1978047',
    'break_records' => [],
    'clock_in_at' => "#{date}T09:10:00",
    'clock_out_at' => "#{date}T18:20:00"
  }
  req_options = {
    use_ssl: uri.scheme == "https"
  }

  # Create the HTTP objects
  req = Net::HTTP::Delete.new(uri)
  # header
  req["Authorization"] = "Bearer #{access_token}"
  req["Content-Type"] = "application/json"
  req.body = body.to_json

  # Send the request
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(req)
  end

  pp response.body

  # refresh
  refresh
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
  dakoku_record
end

post '/dakoku_record', provides: :json do
  params = JSON.parse request.body.read
  pp params
  dakoku_record params['date']
end

def dakoku
  last_dakoku = get_for_dakoku_list.last
  # 出勤していない場合は、出勤する
  if Date.parse(last_dakoku['date']) != Date.today
    post_for_dakoku(type: 'clock_in')
    return
  end

  # 出勤、退勤を繰り返す
  case last_dakoku['type']
  when 'break_begin'
    post_for_dakoku(type: 'break_end')
  when 'break_end'
    post_for_dakoku(type: 'break_begin')
  end
end

def dakoku_record(date)
  delete_for_dakoku_record(date: date)
  put_for_dakoku_record(date: date)
end

def refresh
  # 一旦環境変数から取得する(dbに移すなど)
  # access_token = ENV.fetch('ACCESS_TOKEN') { '' }
  # refresh_token = ENV.fetch('REFRESH_TOKEN') { '' }
  # expires_at = ENV.fetch('EXPIRES_AT') { '' }
  access_token, refresh_token, expires_at = PG_CLIENT.get_token

  response = OAUTH2.refresh_token(access_token, refresh_token, expires_at)
  pp response

  PG_CLIENT.update_token(response.token.to_s, response.refresh_token.to_s, response.expires_in.to_s)

  pp PG_CLIENT.get_token
end

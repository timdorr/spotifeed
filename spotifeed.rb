require 'rubygems'
require 'bundler'

Bundler.require

$conn = Faraday.new 'https://api.spotify.com/v1/' do |conn|
  conn.response :json
end

class Token
  def initialize
    @token_expiry = Time.now
  end

  def refresh
    return unless @token_expiry <= Time.now

    res = $conn.post(
      'https://accounts.spotify.com/api/token',
      'grant_type=client_credentials',
      'Authorization' => "Basic #{Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")}"
    )

    token_expiry = Time.now + res.body["expires_in"]
    $conn.headers['Authorization'] = "Bearer #{res.body["access_token"]}"
  end
end

token = Token.new

get '/' do
  token.refresh

  JSON.generate $conn.get("shows/#{ENV['SHOW_ID']}?market=US").body
end

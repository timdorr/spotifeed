class Spotify
  def initialize
    @token_expiry = Time.now
    @conn = Faraday.new 'https://api.spotify.com/v1/' do |conn|
      conn.response :json
    end
  end

  def conn
    refresh
    @conn
  end

  def refresh
    return unless @token_expiry <= Time.now

    puts "Refreshing token!"

    res = @conn.post(
      'https://accounts.spotify.com/api/token',
      'grant_type=client_credentials',
      'Authorization' => "Basic #{Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")}"
    )

    @token_expiry = Time.now + res.body["expires_in"]
    @conn.headers['Authorization'] = "Bearer #{res.body["access_token"]}"
  end
end

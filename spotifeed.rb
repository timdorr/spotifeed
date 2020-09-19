require './spotify'

class Redis
  def cache(key, expire = nil)
    if (value = get(key)).nil?
      value = yield(self)
      set(key, value)
      expire(key, expire) if expire
      value
    else
      value
    end
  end
end

$redis = Redis.new

class Spotifeed < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  attr_reader :spotify

  def initialize
    super
    @spotify = Spotify.new
  end

  get '/?:show_id?' do
    show_id = params[:show_id] || ENV['SHOW_ID']
    return '' unless show_id =~ /\A\w{22}\z/

    show = $redis.cache("show:#{show_id}", 3600) do
      JSON.generate spotify.conn.get("shows/#{show_id}?market=US").body
    end
    show = JSON.parse(show)

    return 'Not a valid show' if show['error']

    content_type 'application/rss+xml; charset=utf-8'
    RSS::Maker.make('rss2.0') do |rss|
      rss.channel.title = show['name']
      rss.channel.description = show['description']
      rss.channel.itunes_summary = show['description']
      rss.channel.link = show.dig('external_urls', 'spotify')
      rss.channel.author = show['publisher']
      rss.channel.itunes_author = show['publisher']

      rss.image.url = show.dig('images', 0, 'url')
      rss.image.title = show['name']
      rss.channel.itunes_image = show.dig('images', 0, 'url')

      rss.channel.updated = Time.parse(show.dig('episodes', 'items', 0, 'release_date') || '01-01-2020').to_s
      rss.channel.generator = 'Spotifeed'

      rss.items.do_sort = true
      show.dig('episodes', 'items').each do |episode|
        rss.items.new_item do |item|
          item.guid.content = episode['uri']
          item.title = episode['name']
          item.description = episode['description']
          item.date = Time.parse(episode['release_date'] || '01-01-2020').to_s

          item.itunes_image = episode.dig('images', 0, 'url')
          item.itunes_explicit = episode['explicit']

          item.link = "https://anon-podcast.scdn.co/#{episode['audio_preview_url'].split('/').last}"
          item.enclosure.url = "https://anon-podcast.scdn.co/#{episode['audio_preview_url'].split('/').last}"
          item.enclosure.length = 1234567
          item.enclosure.type = 'audio/mpeg'
        end
      end
    end.to_s
  end
end

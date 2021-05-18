require "./spotify"

class Redis
  def cache(key, expire = nil)
    value = get(key)

    if value.nil?
      value = yield(self)
      set(key, value)
      expire(key, expire) if expire
    end

    value
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

  get "/" do
    File.read(File.join("public", "index.html"))
  end

  get "/:show_id" do
    show_id = params[:show_id] || ENV["SHOW_ID"]
    return "" unless /\A\w{22}\z/.match?(show_id)

    show = $redis.cache("show:#{show_id}", 3600) do
      JSON.generate spotify.conn.get("shows/#{show_id}?market=US").body
    end
    show = JSON.parse(show)

    return "Not a valid show" if show["error"]

    max_episodes = ENV.fetch("MAX_EPISODE_COUNT", 0).to_i
    limit = 50
    max_episodes.times.each_slice(limit).map(&:first).each do |offset|
      next if offset.zero?

      episodes = $redis.cache("show:#{show_id}-#{offset}") do
        JSON.generate spotify.conn.get("shows/#{show_id}/episodes?market=US&limit=#{limit}&offset=#{offset}").body
      end
      episodes = JSON.parse(episodes)

      show.dig("episodes", "items").concat(episodes.dig("items"))

      break if episodes.dig("items").count < 50
    end

    content_type "application/rss+xml; charset=utf-8"
    RSS::Maker::RSS20.make do |rss|
      rss.channel.title = show["name"]
      rss.channel.description = show["description"]
      rss.channel.itunes_summary = show["description"]
      rss.channel.link = show.dig("external_urls", "spotify")
      rss.channel.author = show["publisher"]
      rss.channel.itunes_author = show["publisher"]
      rss.channel.language = show["languages"].first
      rss.channel.itunes_block = true

      rss.image.url = show.dig("images", 0, "url")
      rss.image.title = show["name"]
      rss.channel.itunes_image = show.dig("images", 0, "url")

      rss.channel.updated = Time.parse(show.dig("episodes", "items", 0, "release_date") || "01-01-2020").to_s
      rss.channel.generator = "Spotifeed"

      rss.items.do_sort = true
      show.dig("episodes", "items").each do |episode|
        rss.items.new_item do |item|
          duration_secs = (episode["duration_ms"] / 1000).floor

          item.guid.content = episode["uri"]
          item.title = episode["name"]
          item.description = episode["description"]
          item.date = Time.parse(episode["release_date"] || "01-01-2020").to_s

          item.itunes_subtitle = episode["description"]
          item.itunes_image = episode.dig("images", 0, "url")
          item.itunes_duration = "%02d:%02d:%02d" % [duration_secs / 3600, duration_secs / 60 % 60, duration_secs % 60]
          item.itunes_explicit = episode["explicit"]

          item.link = episode.dig("external_urls", "spotify")
          # item.enclosure.url = "https://anon-podcast.scdn.co/#{episode["audio_preview_url"].split("/").last}"
          # item.enclosure.length = 0
          # item.enclosure.type = "audio/mpeg"
        end
      end
    end.to_s
  end
end

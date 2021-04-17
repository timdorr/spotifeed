<p align="center">
  <img src="https://media.giphy.com/media/f9SyS82mgPi4vYeppV/giphy.gif">
</p>

<h3 align="center">
  Spotifeed
</h3>

<p align="center">
  A Spotify Podcast RSS Feed Generator
</p>

---

A simple service to serve up Spotify podcasts as RSS feeds for use in any podcast app. 


Just take the show ID from the end of the Show Link on Spotify and put it at the end of `https://spotifeed.timdorr.com/`, like so:

```
https://open.spotify.com/show/4rOoJ6Egrf8K2IrywzwOMk -> https://spotifeed.timdorr.com/4rOoJ6Egrf8K2IrywzwOMk
```

## Installation
Provided in this Repo is a Dockerfile and docker-compose file for easy deployment.  
To build the image run `docker-compose build spotifeed`  

The following environment variables need to be set:  
`SHOW_ID`: The default show ID to be displayed  
`SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET`: Create a Spotify App at https://developer.spotify.com/dashboard/applications and use the credentials here  
`REDIS_URI`: The URI of the local redis server (e.g. `redis://redis:6379`)  
`BASE_URL`: The base URL at which the application can be found (e.g. `http://localhost:9292`)  
`PORT`: The Port the container should run on

The following Environment variables are optional:
`MAX_EPISODE_COUNT`: This will change the number of episodes fetched for each requests. You may run into issues when making many requests due to Spotify's rate-limiting

###### _Spotify® is a trademark of Spotify AB which does not sponsor, authorize, or endorse this project._

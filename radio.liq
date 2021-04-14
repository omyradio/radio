# LiquidSoap script to define the omyradio.net webradio stream
# must inject variables:
# * stream_pwd for the live stream password
# * icecast_pwd for the icecast to stream to

set("server.telnet", true)
set("log.stdout", true)
set("harbor.bind_addr", "0.0.0.0")

silence = blank()

tunes = playlist("#{basedir}/audio/tunes",mode="randomize", reload_mode="watch")
tom_recordings =playlist("#{basedir}/audio/tom",mode="randomize", reload_mode="watch")
jingles = playlist("#{basedir}/audio/jingles")

computa_selecta = rotate(weights=[1,3], [jingles, tunes])

scheduled_source = switch([
  ({ (7w) and 22h00-24h00 }, tom_recordings),
  ({ true }, computa_selecta)
])

live = input.harbor(
  "live",
  port=8001,
  password=stream_pwd,
  user="source"
)

# append LIVE-ON-AIR to title if we are live
def append_title(m)=
  title=m["title"]
  [("title","#{title} - LIVE-ON-AIR")]
end

live=map_metadata(append_title,live)

source_chain = fallback(
  track_sensitive=false,
  [live, scheduled_source, silence]
)

# dump live_dj recordings to a file
timestamp = '%H-%M--%d-%m-%Y'
output.file(%mp3(bitrate=320, id3v2=true), reopen_on_metadata=false, "#{basedir}/audio/rec/OMYLiveRecordedOn#{timestamp}.mp3", live, fallible=true)

radio = source_chain

output.icecast(
  %mp3(
    bitrate=128
  ),
  host="localhost",
  port=8000,
  user="source",
  password=icecast_pwd,
  mount="stream-mp3",
  name="Omyradio MP3 stream",
  radio
)

output.icecast(
  %vorbis.cbr(samplerate=44100, channels=2, bitrate=128),
  host="localhost",
  port=8000,
  user="source",
  password=icecast_pwd,
  mount="stream-vorbis",
  name="Omyradio vorbis stream",
  radio
)

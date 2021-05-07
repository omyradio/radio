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
lifeindub =playlist("#{basedir}/audio/lifeindub",mode="randomize", reload_mode="watch")
jingles = playlist("#{basedir}/audio/jingles")

computa_selecta = rotate(weights=[1,3], [jingles, tunes])

scheduled_source = switch([
  ({ (7w) and 21h00-24h00 }, tom_recordings),
  ({ (5w) and 16h20-18h00 }, lifeindub),
  ({ true }, computa_selecta)
])

livenormal = audio_to_stereo(input.harbor(
  "live",
  port=8001,
  password=stream_pwd,
  user="source",
  max=20.
))

# input with inreased buffer (4x) for DJs with bad connection
livelag = audio_to_stereo(input.harbor(
  "livelag",
  port=8001,
  password=stream_pwd,
  user="source",
  buffer=8.,
  max=20.
))

# append LIVE-ON-AIR to title if we are live
def append_title(m)=
  title=m["title"]
  [("title","#{title} - LIVE-ON-AIR")]
end

livenormal=map_metadata(append_title,livenormal)
livelag=map_metadata(append_title,livelag)

live = fallback([strip_blank(max_blank=24.0,mksafe(livenormal)),strip_blank(max_blank=24.0,mksafe(livelag))])

source_chain = fallback(
  track_sensitive=false,
  [live, scheduled_source, silence]
)

# dump live_dj recordings to a file
timestamp = '%d-%m-%Y_%Hh%Mm'
title='$(if $(title),"$(title)","Unknown archive")'
output.file(
  %mp3(bitrate=320, id3v2=true),
  reopen_on_metadata=true,
  '#{basedir}/audio/rec/OMYLiveRecordedOn#{timestamp}_#{title}.mp3',
  live,
  fallible=true
)

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
  mount="stream-vorbis-128",
  name="Omyradio vorbis stream 128kbps",
  radio
)

output.icecast(
  %vorbis.cbr(samplerate=44100, channels=2, bitrate=320),
  host="localhost",
  port=8000,
  user="source",
  password=icecast_pwd,
  mount="stream-vorbis-320",
  name="Omyradio vorbis stream 320kbps",
  radio
)

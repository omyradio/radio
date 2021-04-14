# radio
The liquidsoap script to define the webradio


# environment
This scripts needs 2 passwords and one path so you might wrap it into another liquidsoap script to provide those like:

```
stream_pwd = "MYSECUREPASS"
icecast_pwd = "MYSECUREPASS"
basedir = "/home/radio/"

%include "radio.liq"
```

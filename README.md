# yt2cd
lazy man's youtube download script 

A close sibling to [mpdp2acd](https://github.com/Brod8362/mpdp2acd), except now I've grown too lazy to source and organize the music myself. Also, now I can have more than 80 minutes of music on a single disc.

Dependencies
============
`ffmpeg`, `cdrecord`, `mkisofs`, `youtube-dl`

For a quick setup on arch: 
`sudo pacman -S ffmpeg cdrtools youtube-dl`

Notes
=====
This should allow multi-session writing, so ideally you can keep writing to the same disc and adding music.
However currently there's no check in place for that, so it'll just write the same songs again even if they're already there.
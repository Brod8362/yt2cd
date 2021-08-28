#!/bin/sh

info () {
  echo "INFO> $1"
}

warn () {
  echo -e "\e[33mWARN>\e[0 $1"
}

error () {
  echo -e "\e[31mERROR>\e[0 $1"
}

yes_no () {
  read -r -p "$1 (Y/n)" input
  if [ $input = "Y" ] || [ $input = "y" ]; then
    return 1
  fi
  return 0
}

generate_session () {
  info "Creating CD session..."
  mkisofs -M $1 -C "$(cdrecord dev=$1 -msinfo)" -V "YT2CD" -J -r -o session.iso ./music  
}

write_session () {
  info "Beginning cdrecord..."
  cdrecord -v -multi dev=$1 session.iso
  if [ $? -ne 0 ]; then
    error "cdrecord exited with non-zero exit code"
    exit 4
  fi
}

util_check=0
command -v mkisofs &>/dev/null
util_check+=$?
command -v youtube-dl &>/dev/null
util_check+=$?
command -v ffmpeg &>/dev/null
util_check+=$? 
command -v cdrecord &>/dev/null
util_check+=$?
if [ $util_check -ne 0 ]; then
  error "Missing one or more required utilities. Ensure ffmpeg, mkisofs, cdrecord, and youtube-dl are installed."
  exit 1
fi

echo "Youtube playlist URL:"
read url

if [ -d "./yt2cd_data" ]; then
  yes_no "A data folder for yt2cd already exists. Do you want to delete it?"
  if [ $? -eq 1 ]; then
    rm -r yt2cd_data
  fi

fi

mkdir -p yt2cd_data/music
cd yt2cd_data
#start the videos downloading
youtube-dl --download-archive downloaded.txt -xiq --audio-format mp3 "$url" -o "music/%(title)s.%(ext)s" &
info "Began video downloading"

cd_path="/dev/sr0"
read -r -p "Path to CD drive [default $cd_path]:" cd_path_tmp
if [ ! $cd_path_tmp = "" ]; then
  cd_path=cd_path_tmp
fi

info "Waiting for youtube-dl..."
wait
if [ $? -eq 1 ]; then
  error "youtube-dl returned with non-zero exit code $?"
  exit 2
fi

generate_session $cd_path
write_session $cd_path


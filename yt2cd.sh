#!/bin/sh

info () {
  echo "INFO> $1"
}

warn () {
  echo -e "\e[33mWARN>\e[0 $1"
}

error () {
  echo -e "\e[31mERROR>\e0 $1"
}

yes_no () {
  read -r -p "$1 (Y/n)" input
  if [ $input = "Y" ] || [ $input = "y" ]; then
    return 1
  fi
  return 0
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
echo "Path to CD drive [default $cd_path]:"
read cd_path_tmp
if [ ! $cd_path_tmp = "" ]; then
  cd_path=cd_path_tmp
fi

if [ ! -f "$cd_path" ]; then
  error "Path $cd_path not found."
  exit 3
fi

info "Waiting for youtube-dl..."
wait
if [ $? -eq 1 ]; then
  error "youtube-dl returned with non-zero exit code $?"
  exit 2
fi

# TODO allow renaming the volume here instead of just YT2CD
info "Creating CD session..."
mkisofs -M $cd_path -C "$(cdrecord dev=$cd_path -msinfo)" -V "YT2CD" -J -r -o session.iso ./music
info "Beginning cdrecord..."
cdrecord -v -multi dev=$cd_path session.iso
if [ $? -ne 0 ]; then
  error "cdrecord exited with non-zero exit code"
  exit 4
fi

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
  sessinfo=$(cdrecord dev=$1 -msinfo)
  if [ $? -ne 0 ]; then
    mkisofs -M $1 -C $sessinfo -V "YT2CD" -J -r -o session.iso ./music  
  else
    mkisofs -M $1 -V "YT2CD" -J -r -o session.iso ./music  
  fi
  return $?
}

write_session () {
  info "Beginning cdrecord..."
  cdrecord -v -multi dev=$1 session.iso
  return $?
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

read -r -p  "Youtube playlist URL:" url

if [ -d "./yt2cd_data" ]; then
  yes_no "A data folder for yt2cd already exists. Do you want to delete it?"
  if [ $? -eq 1 ]; then
    rm -r yt2cd_data
  fi

fi

mkdir -p yt2cd_data/music
cd yt2cd_data

if [ -f "session.iso" ]; then 
  yes_no "A previous session exists. Would you like to try writing it to the disc?"
  if [ $? -eq 1 ]; then
    write_session
    exit 0
  else 
    yes_no "Would you like to delete it?"
    if [ $? -eq 1 ]; then
      info "Previous sesson deleted."
      rm session.iso
    else
      info "Exiting..."
      exit 0
    fi
  fi
fi

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
  error "youtube-dl returned with non-zero exit code"
  exit 2
fi

generate_session $cd_path
if [ $? -ne 0 ]; then
  error "mkisofs returned with non-zero exit code"
  exit 3
fi

write_session $cd_path
if [ $? -ne 0 ]; then
  error "cdrecord returned with non-zero exit code"
  exit 4
fi

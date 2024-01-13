#!/usr/bin/env bash

while true; do
  echo "rendering webp"
  pixlet render /root/home.star ha_key=$HA_KEY

  echo "pushing to Tidbyt servers"
  curl --request POST \
    --url https://api.tidbyt.com/v0/devices/$TB_DEVICE/push \
    --header "Authorization: Bearer $TB_KEY" \
    --header 'Content-Type: application/json' \
    --data '{"image":"'$(base64 -w 0 -i /root/home.webp)'", "installationID":"Home"}'

  echo "waiting for the next minute"
  sleep $((60 - $(date +%S)))
done

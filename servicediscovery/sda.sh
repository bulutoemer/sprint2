#!/bin/bash

trap "exit 0" SIGHUP SIGINT SIGTERM

while true
do
  inst="$(exo instancepool show $EXOSCALE_INSTANCEPOOL_ID -z $EXOSCALE_ZONE --output-template "{{ .Instances }}" --output-format json)"
  inst=${inst#"["}
  inst=${inst%"]"}
  instarray=($inst)
  echo "[{\"targets\": [" > /srv/service-discovery/config.json
  declare -i anzahl=${#instarray[@]}
  declare -i i=1
  for instance in "${instarray[@]}"
  do
    if [[ $i -eq $anzahl ]]
    then
      echo \""$(exo vm show $instance --output-template "{{ .IPAddress }}"):$TARGET_PORT"\" >> /srv/service-discovery/config.json
    else
      echo \""$(exo vm show $instance --output-template "{{ .IPAddress }}"):$TARGET_PORT"\", >> /srv/service-discovery/config.json
    fi
    i=$((i+1))
  done
  echo "]}]" >> /srv/service-discovery/config.json
  sleep 15
done
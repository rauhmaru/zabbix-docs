#!/bin/bash
# Verifica o status dos servicos, baseados em systemd

Service=$1
systemctl list-units --no-page -t service -a | awk /.service/'{{ gsub(".service","");gsub("^..",""); if ( $1 == "'$Service'" ) print $4 }}'

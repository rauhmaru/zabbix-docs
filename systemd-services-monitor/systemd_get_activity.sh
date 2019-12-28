#!/bin/bash
# Verifica se os servicos do systemd estao ativos

Service=$1
systemctl list-units --no-page -t service -a | awk /.service/'{{ gsub(".service","");gsub("^..",""); if ( $1 == "'$Service'" ) print $3 }}'

#!/bin/bash
# Verifica se os servicos do systemd estao ativos
# Raul Liborio, rauhmaru@opensuse.org / gmail.com
# v0.1 - 27/01/2019

Service=$1
systemctl list-units --no-page -t service -a | awk /.service/'{{ gsub(".service","");gsub("^..",""); if ( $1 == "'$Service'" ) print $3 }}'

#!/bin/bash
# Lista os servicos e verifica se estao em execucao, usando systemd
# Raul Liborio, rauhmaru@opensuse.org / gmail.com
# v0.1 - 27/01/2019

tmpfile=$( mktemp )
jsonFile=$( mktemp )

# Todos os servicos
systemctl list-units --no-page -t service -a | awk /.service/'{ gsub(".service","");gsub("^..",""); print }' > $tmpfile

# Criacao do json
TotalDeLinhas=$( wc -l < $tmpfile )
Final=$(( TotalDeLinhas -1  ))
	
# Criacao do arquivo json
echo -e "{\n  \"data\":["

# Loop para composicao do arquivo json
while read Unit Load Active Sub Description; do
	echo -e "    {
      \"{#SERVICE_NAME}\":\"$Unit\",
      \"{#SERVICE_LOAD}\":\"$Load\",
      \"{#SERVICE_ACTIVE}\":\"$Active\",
      \"{#SERVICE_SUB}\":\"$Sub\",
      \"{#SERVICE_DESCRIPTION}\":\"$Description\""
	
	let Contador++
		if [[ $Contador -le $Final ]]; then
			echo -e "    },"
	else
			echo -e "    }\n  ]\n}"
	fi
done < $tmpfile
	
rm -f $tmpfile $jsonfile

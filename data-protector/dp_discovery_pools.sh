#!/bin/bash
# Lista os servicos e verifica se estao em execucao

OLDLANG="$LANG"
LANG="en_US.utf8"

tmpfile=$( mktemp )
sudo /opt/omni/bin/omnimm -show_pools -detail | awk -F ' : ' '/Pool name/{ print $NF}' > $tmpfile

# Criacao do json
TotalDeLinhas=$( wc -l < $tmpfile )
Final=$(( TotalDeLinhas -1  ))

# Loop para composicao do arquivo json
echo -e "{\n\t\"data\":[\n"
while read PoolName; do
echo -e "  {"
                echo -e "    \"{#POOLNAME}\":\"$PoolName\""
                let Contador++
                        if [[ $Contador -le $Final ]]; then
                                echo -e "  },\n"
                else
                                echo -e "  }\n]\n}"
                fi
done < $tmpfile

rm -f $tmpfile

LANG=$OLDLANG

exit 0

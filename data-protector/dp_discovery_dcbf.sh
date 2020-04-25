#!/bin/bash
# LLD to find DCBF directories size
# Raul Liborio rauhmaru@opensuse.org
# https://github.com/rauhmaru

OLDLANG="$LANG"
LANG="en_US.utf8"
tmpfile=$( mktemp )
ReportFile="/tmp/omnirpt_rpt_dbsize.out"

awk '/Detail Catalog Binary Files/,0{ if ($1 ~ /dcbf/ && $3 ~ /[0-9]$/ ) print $1,$NF}' $ReportFile > $tmpfile


# Criacao do json
TotalDeLinhas=$( wc -l < $tmpfile )
Final=$(( TotalDeLinhas -1  ))

sed -i 's/ .*//g;' $tmpfile
# Loop para composicao do arquivo json
echo -e "{\n\t\"data\":[\n"

while read DCBF; do
echo -e "  {"
                echo -e "    \"{#DCBF}\":\"$DCBF\""
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

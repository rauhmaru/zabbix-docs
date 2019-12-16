#!/bin/bash
#
#     Script padr�o para uso no MySQL para backup dos banco com
#     notifica��o por envio de email e registro no arq. de log
#     local.
#
########################################################

BACKUP=/backup/srvarquivos
DATA=`/bin/date +%Y%m%d.%H%M`
DATACAB=`/bin/date +%d/%m/%Y-%A`
ADMINBKP="dalton.oliveira@solutis.com.br,felipe.cunha@solutis.com.br,dba@solutis.net.br"

DIRLOG=/var/log/backup
ERRORLOG=$DIRLOG/dump-mysql.errorlog
LOG=$DIRLOG/dump-mysql.log
TmpFile="/tmp/mysqlDatabasesSize.txt"

#Define o CLIENTE e Host do servidor
CLIENTE="MPBA"
HOST=`hostname`
SERVIDOR="localhost"

USER="operador"
PASSWORD="operador"

########################################################

InicioExecucao=$( date +%s )
ErrosDump=0
ErrosCompactacao=0

function zabbix {
  # Envia informações via zabbix_sender para o servidor Zabbix
  # Chaves existentes
  # solutis.backup.status = Status do ultimo backup
  # solutis.backup.status.zip = Status da compactacao do ultimo backup
  # solutis.backup.duracao = Duracao do ultimo backup
  # solutis.backup.duracao.zip = Duracao da compactacao do ultimo backup
  # solutis.backup.tamanho = Tamanho do ultimo backup
  # solutis.backup.tamanho.zip = Tamanho do ultimo backup
  # solutis.backup.tamanho.total = Tamanho total do ultimo backup
  # solutis.backup.duracao.execucao = Tamanho do ultimo backup
  # solutis.backup.erros.dump = Total de erros na execucao do backup
  # solutis.backup.erros.compactacao = Total de erros na compactacao do backup

  # Arquivo de configuracao do Zabbix Agent
  ZabbixConfigFile="/etc/zabbix/zabbix_agentd.conf"
  # Nome do host exatamente como cadastrado no Zabbix Server
  ZabbixHostName="$HOST"
  # Endereco do Zabbix
  ZabbixServer="10.43.2.29"

  zabbix_sender -c ${ZabbixConfigFile} -s "${ZabbixHostName}" -k solutis.backup.${1}${3} -o "${2}" -z ${ZabbixServer}
}



QtdeBases=$( /scripts/mysql_lista_bases.sh | grep -c BASE )
zabbix total.bases ${QtdeBases}


TamanhoTotalDumpsBackup=0

####################################################

if [ ! -d $DIRLOG ];then
        mkdir -p $DIRLOG
        >$ERROLOG
        >$LOG
fi

databases=`mysql -h$SERVIDOR -u$USER -p$PASSWORD -e 'show databases;'| egrep -v 'Database|information_schema|lost\+found|sys|performance_schema'`


echo "---------------------------------------------------------" > $LOG
echo "                 Iniciando o BACKUP                      " >> $LOG
echo "                     $CLIENTE                            " >> $LOG
echo "          $DATACAB  -  $HOST                             " >> $LOG
echo "---------------------------------------------------------" >> $LOG
echo " "

cd $BACKUP

mysql -u $USER -hlocalhost -p$PASSWORD -e \
'SELECT table_schema AS "Database",\
 ROUND(SUM(data_length + index_length)) \
 AS "Size (B)" \
 FROM information_schema.TABLES \
 GROUP BY table_schema;' > $TmpFile

for banco in $databases; do

    InicioBackup=$( date +%s )
    echo "$banco - Criando DUMP" >> $LOG
    if [ "$banco" != "performance_schema" ]; then


           mysqldump -h$SERVIDOR -u$USER -p$PASSWORD $banco --extended-insert --quick --routines --events --triggers >> $banco-$DATA.dmp
           Status=$( echo $?)
           echo "Status do backup de $banco foi $?" >> backup_status.txt
           TerminoBackup=$( date +%s )
           DuracaoBackup=$((TerminoBackup-InicioBackup))
           TamanhoBackup=$( du -sbc ${banco}-$DATA.dmp | awk /total/'{ print $1 }')
           echo "Duracao do backup: ${DuracaoBackup}" >> ${LOG}
  
          TamanhoBanco=$(awk /$banco/'{ print $NF }' $TmpFile )
          zabbix database.size ${TamanhoBanco} [$banco]
          echo -e "zabbix database.size ${TamanhoBanco} [$banco]\n"

           if [ $Status != 0 ]; then
              echo "$ - Ocorreu algum erro durante o dump !!!" >>${LOG}
              let ErrosDump++
              zabbix status 1 [$banco]

           else
              echo " - Arquivo Integro !" >>${LOG}
              zabbix status 0 [$banco]

             fi
       echo " - Tamanho DUMP :  $( du -sh $banco-$DATA.dmp )" >> $LOG
             InicioCompactacaoBackup=$( date +%s )
             gzip -9 $banco-$DATA.dmp
             TerminoCompactacaoBackup=$( date +%s )
             DuracaoCompactacaoBackup=$((TerminoCompactacaoBackup-InicioCompactacaoBackup))

             TamanhoBackupZip=$( du -sbc ${banco}-$DATA.dmp.gz | awk /total/'{ print $1 }')

       echo " - DUMP COMPACTADO " >> $LOG
       if [ ! -e  $BACKUP/$banco-$DATA.dmp.gz ]; then
              echo "$DATA - $banco -> Problemas com dump" >> $LOG
              let ErrosCompactacao++
              zabbix status.zip 1 [$banco]

       else
              zabbix status.zip 0 [$banco]

             # Compactado DUMP de $banco
              echo "  $banco - Tamanho COMPACTADO :  $( du -sh $banco-$DATA.dmp.gz )" >> $LOG
              echo "  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -" >> $LOG

       fi
    fi
    echo "Tamanho do backup compactado: ${TamanhoBackupZip}" >> ${LOG}
    zabbix tamanho.zip ${TamanhoBackupZip} [$banco]

    echo "Duracao da compactacao: ${DuracaoCompactacaoBackup}" >> ${LOG}
    zabbix duracao.zip ${DuracaoCompactacaoBackup} [$banco]
    zabbix duracao ${DuracaoBackup} [$banco]
    zabbix tamanho ${TamanhoBackup} [$banco]

    TamanhoTotalDumpsBackup=$((TamanhoTotalDumpsBackup+TamanhoBackup))

done

TerminoExecucao=$( date +%s )
DuracaoExecucao=$((TerminoExecucao-InicioExecucao))
TamanhoTotalBackup=$( du -bsc *-${DATA}.dmp.gz | awk /total/'{ print $1}' )
zabbix tamanho.total ${TamanhoTotalBackup}
zabbix duracao.execucao ${DuracaoExecucao}
zabbix erros.dump ${ErrosDump}
zabbix erros.compactacao ${ErrosCompactacao}
zabbix tamanhodumps.total $TamanhoTotalDumpsBackup


echo "---------------------------------------------------------" >> $LOG
echo "           Backup finalizado com sucesso!                " >> $LOG
echo "---------------------------------------------------------" >> $LOG

# Envia um e-mail para o administrador no final do processo de backup com o arquivo de LOG
## Adicao de mais informacoes em $LOG (Raul Liborio, 11/06/2016)
echo "  TOTAL OCUPADO AREA : $(df -h | awk /backup/'{print $5,$2,"do Volume :",$1}' |  tail -1 )" >> $LOG


# Envia um e-mail para o administrador no final do processo de backup com o arquivo de LOG

mail -s "Backup $CLIENTE - $HOST - MySQL " $ADMINBKP < $LOG

# Exclui backups mais antigos que 7 dias
/usr/bin/find /backup/srvarquivos  -name "*.dmp.gz" -mtime +6 -and -not -type d -delete



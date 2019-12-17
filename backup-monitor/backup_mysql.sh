#!/bin/bash
#
#     Script padrao para uso no MySQL para backup dos banco com
#     notificacao por envio de email e registro no arq. de log
#     local.
#
########################################################

# Local de armazenamento dos backups
BACKUP=/backups/
DATA=$( date +%Y%m%d.%H%M )
DATACAB=$( date +%d/%m/%Y-%A )

# Emails das pessoas que devem ser notificadas
ADMINBKP="john.doe@mail.com "
DIRLOG="/var/log/backup"
ERRORLOG="$DIRLOG/dump-mysql.errorlog"
LOG="$DIRLOG/dump-mysql.log"
TmpFile="/tmp/mysqlDatabasesSize.txt"
#Define o CLIENTE e Host do servidor
CLIENTE="Empresa de Seu Joao"
HOST=$( hostname )
SERVIDOR="localhost"
# Credenciais
USER="operador"
PASSWORD="operador"

########################################################

# Inicio do backup
InicioExecucao=$( date +%s )
ErrosDump=0
ErrosCompactacao=0

function zabbix {
  # Envia informações via zabbix_sender para o servidor Zabbix
  # Chaves existentes
  # backup.status = Status do ultimo backup
  # backup.status.zip = Status da compactacao do ultimo backup
  # backup.duracao = Duracao do ultimo backup
  # backup.duracao.zip = Duracao da compactacao do ultimo backup
  # backup.tamanho = Tamanho do ultimo backup
  # backup.tamanho.zip = Tamanho do ultimo backup
  # backup.tamanho.total = Tamanho total do ultimo backup
  # backup.erros.dump = Total de erros na execucao do backup
  # backup.erros.compactacao = Total de erros na compactacao do backup

  # Arquivo de configuracao do Zabbix Agent
  ZabbixConfigFile="/etc/zabbix/zabbix_agentd.conf"
  # Nome do host exatamente como cadastrado no Zabbix Server
  ZabbixHostName="$HOST"
  # Endereco do Zabbix
  ZabbixServer="192.168.1.1"

  zabbix_sender -c ${ZabbixConfigFile} -s "${ZabbixHostName}" -k backup.${1}${3} -o "${2}" -z ${ZabbixServer}
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

# Listagem das bases que entrarao no backup. Caso deseje adicionar mais alguma na lista, adicione um pipe ( | ) e o nome em seguida, sem espacos
databases=`mysql -h$SERVIDOR -u$USER -p$PASSWORD -e 'show databases;'| egrep -v 'Database|information_schema|lost\+found|sys|performance_schema'`


echo "---------------------------------------------------------" > $LOG
echo "                 Iniciando o BACKUP                      " >> $LOG
echo "                     $CLIENTE                            " >> $LOG
echo "          $DATACAB  -  $HOST                             " >> $LOG
echo "---------------------------------------------------------" >> $LOG
echo " "

cd $BACKUP

# Exibe o tamanho total do banco de dados
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

		# Dump da base
           mysqldump -h$SERVIDOR -u$USER -p$PASSWORD $banco --extended-insert --quick --routines --events --triggers >> $banco-$DATA.dmp
           Status=$( echo $? )
           TerminoBackup=$( date +%s )
           DuracaoBackup=$((TerminoBackup-InicioBackup))
           TamanhoBackup=$( wc -c < ${banco}-$DATA.dmp )
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

             TamanhoBackupZip=$( wc -c < ${banco}-$DATA.dmp.gz )

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
echo "  TOTAL OCUPADO AREA : $(df -h | awk /backup/'{print $5,$2,"do Volume :",$1}' |  tail -1 )" >> $LOG
mail -s "Backup $CLIENTE - $HOST - MySQL " $ADMINBKP < $LOG

# Exclui backups mais antigos que 7 dias
find $BACKUP  -name "*.dmp.gz" -mtime +6 -and -not -type d -delete



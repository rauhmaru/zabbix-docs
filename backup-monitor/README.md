# backup-monitor

## Por que devo usar?
O backup monitor pode ser utilizado para monitoramento de cada passo realizado pelo script de backup, fornecendo métricas e indicadores para acompanhamento de seu backup. Todos os valores são enviados via ```zabbix-sender``` para o Zabbix Server.

## Motivação
O Backup monitor surgiu de uma vontade de ajudar o DBA de nossa empresa. Todo o processo do backup do banco de dados é feito via shell-script (procedimento muito comum com bases MySQL e PostgreSQL) e seus resultados enviados por e-mail. A partir do momento em que você tem mais de 10 servidores de banco de dados e algo em torno de 100 ou mais bases de dados, com backup 2 vezes ao dia, ler esses emails se torna um trabalho bastante chato e com grande facilidade de algo passar desapercebido. Com esses dados no Zabbix, o DBA poderá agora obversar todas as informações em telas que ele pode criar e tratar as falhas que o zabbix notificar via trigger.


#### Screenshots
![Dados recentes](img/bkpmonitor01.PNG)

#### Gráfico do tamanho total do backup
![tamanho do backup total](img/bkpmonitor03.png)

#### Gráfico do tamanho do backup de uma base
![tamanho do backup individual](img/bkpmonitor02.png)


## Configuração
### No servidor de banco de dados
#### Instale o `zabbix-sender` no host
No CentOS:
```shell
yum install zabbix-sender.x86_64
```

Para maiores informações sobre o uso do executável, [consulte a documentação oficial](https://www.zabbix.com/documentation/4.4/manpages/zabbix_sender).

#### Adicionando o arquivo de userparameter
Coloque o arquivo [userparameter_lld.conf](https://github.com/rauhmaru/zabbix-docs/blob/master/backup-monitor/userparameter_lld.conf) no diretório `/etc/zabbix/zabbix_agentd.d`.

Em seguida, reinicie o serviço do agente do Zabbix:
```shell
systemctl restart zabbix-agent
```

#### Configurando o script de LLD (Low Level Discovery)
O script [mysql-lista-bases.sh](https://github.com/rauhmaru/zabbix-docs/blob/master/backup-monitor/mysql-lista-bases.sh) é necessário para listar as bases de dados que serão monitoradas pelo Zabbix. Após adicionar o template no seu servidor de banco de dados no Zabbix, a regra de discovery executará esse script.

Ele executa um `show databases;`, lista as bases, remove o que não é necessário e produz uma saída em JSON, que será utilizada pelo Zabbix Server.

##### Recomendações
*  No meu exemplo, eu o coloquei no diretório `/scripts`. Caso altere esse local, não se esqueça de mudar sua localização também no arquivo [userparameter_lld.conf](https://github.com/rauhmaru/zabbix-docs/blob/master/backup-monitor/userparameter_lld.conf), que é quem invoca e executa esse script. Lembre-se de dar permissão de execução:
```shell
chmod +x /scripts/mysql-lista-bases.sh
```

* Crie um usuário com permissão de apenas leitura para essa rotina. Você pode utilizar também o mesmo usuário que executa o backup das bases.


### No Zabbix Server
Adicione o template [Backup monitor](https://github.com/rauhmaru/zabbix-docs/blob/master/backup-monitor/zbx_template_backup_monitor.xml) ao servidor de banco de dados no Zabbix Server.

#### Mapeamento de valores (Value mapping)
Caso o template não tenha importado os valores de mapeamento necessários para representação dos status dos backups, você pode criá-los em Administração > Geral > Mapeamento de valores. Crie um novo mapeamento de valores com os status:

Valor | Mapeamento
----- | ----------
0 | OK
1 | Falha

No Zabbix 4.2, existem alguns mapeamentos de valores que possuem conteúdo similar, como por exemplo o IDRAC-MIB-SMIv2::BooleanType, QTECH-MIB::sysFanStatus e QTECH-MIB::sysPowerStatus.


#### O template backup monitor
O template [backup monitor](https://github.com/rauhmaru/zabbix-docs/blob/master/backup-monitor/zbx_template_backup_monitor.xml)  é composto por:

Item | Chave | Tipo
---- | ----- | ----
Duração total do backup | backup.duracao.execucao	| Zabbix trapper
Tamanho total dos backups compactados | backup.tamanho.total	| Zabbix trapper
Tamanho total dos dumps | backup.tamanhodumps.total	| Zabbix trapper
Total de bases no backup | backup.total.bases	| Zabbix trapper
Total de erros na compactação do backup | backup.erros.compactacao	| Zabbix trapper
Total de erros no backup | backup.total.erros	| Calculado
Total de erros no dump backup | backup.erros.dump	| Zabbix trapper

* 3 gráficos:
  * Duração dos backups
  * Tamanho total dos backups
  * Total de erros nos backups

1 regra de descoberta, que por sua vez, cria para cada base de dados:

Protótipo de item | chave 
-------------- | ----- 
[{#BASE}] Compactação de backup | backup.status.zip[{#BASE}]	
[{#BASE}] Duração da compactação backup | backup.duracao.zip[{#BASE}]	
[{#BASE}] Duração do backup | backup.duracao[{#BASE}]	
[{#BASE}] Status do backup | backup.status[{#BASE}]	
[{#BASE}] Tamanho do backup | backup.tamanho[{#BASE}]	
[{#BASE}] Tamanho do backup compactado | backup.tamanho.zip[{#BASE}]	
[{#BASE}] Tamanho do banco | backup.database.size[{#BASE}]	
  
* 2 triggers

Trigger | Expressão | Tags
------- | --------- | ----
Falha na compactação da base {#BASE} | 	{Template Backup Monitor:backup.status.zip[{#BASE}].last()}=1 | app:mysql, service:backup
Falha no dump da base {#BASE} | 	{Template Backup Monitor:backup.status[{#BASE}].last()}=1 | app:mysql, service:backup
  
* 2 gráficos
  *	[{#BASE}] Duração do backup
  * [{#BASE}] Tamanho do backup

# O script de coleta de informações
Todos os itens do template são alimentados pelos parâmetros abaixo descritos.

## Parâmetros do script

Chave | Descrição
---- | -----
backup.status | Status do ultimo backup 
backup.status.zip | Status da compactação do ultimo backup
backup.duracao | Duracao do ultimo backup
backup.duracao.zip | Duracao da compactação do último backup
backup.tamanho | Tamanho do ultimo backup
backup.tamanho.zip | Tamanho do último backup compactado
backup.tamanho.total | Tamanho total do último backup (todos os backups)
backup.erros.dump | Total de erros na execução do backup
backup.erros.compactacao | Total de erros na compactação do backup
duracao.execucao | Duração total do backup
tamanhodumps.total | Soma de todos os dumps sem compactação


## Explicando o funcionamento
O script nesse repositório pode ser utilizado tranquilamente, porém, caso queira apenas implementar no seu próprio script, você deverá ter atenção como funciona cada chave para não obter resultados vazios ou incorretos.


### A função zabbix
Todas as informações coletadas durante o script são enviadas via `zabbix-sender`. Para simplificar o seu uso, criei uma função.

*Observação: Você deve alterar as variáveis de acordo com as suas necessidades. Se atente as variáveis ZabbixConfigFile e ZabbixServer*

```shell
function zabbix {
  # Arquivo de configuracao do Zabbix Agent
  ZabbixConfigFile="/etc/zabbix/zabbix_agentd.conf"
  # Nome do host exatamente como cadastrado no Zabbix Server
  ZabbixHostName="$HOST"
  # Endereco do Zabbix
  ZabbixServer="192.168.1.1"

  zabbix_sender -c ${ZabbixConfigFile} -s "${ZabbixHostName}" -k backup.${1}${3} -o "${2}" -z ${ZabbixServer}
}
```

### backup.total.bases
Esse item mostra quantas bases terão seus dados coletados. Por dentro do script de backup, ela executa o script [mysql-lista-bases.sh](https://github.com/rauhmaru/zabbix-docs/blob/master/backup-monitor/mysql-lista-bases.sh) e conta quantas ocorrências da string BASE são exibidas. Esse item é alimentado logo no começo da execução do script:
```shell
QtdeBases=$( /scripts/mysql_lista_bases.sh | grep -c BASE )
zabbix total.bases ${QtdeBases}
```

### backup.status
Status do ultimo backup. Após a execução do dump de cada base, é realizado um teste (```Status=$( echo $? ) ```) para ver se ocorreu um erro ou foi realizado com sucesso:

 ```shell
 mysqldump -h$SERVIDOR -u$USER -p$PASSWORD $banco --extended-insert --quick --routines --events --triggers >> $banco-$DATA.dmp
 Status=$( echo $?)
  ```
  E um pouco mais abaixo do script...

```shell
           if [ $Status != 0 ]; then
              echo "$ - Ocorreu algum erro durante o dump !!!" >>${LOG}
              let ErrosDump++
              zabbix status 1 [$banco]

           else
              echo " - Arquivo Integro !" >>${LOG}
              zabbix status 0 [$banco]

             fi
```
 
  Após o teste, o valor é enviado para o Zabbix. 0 significa que o dump ocorreu com sucesso e 1 que houve erro.
  
  
### backup.status.zip
Status da compactação do último backup. Após o dump, é realizada a compactação do dump, para redução do seu tamanho. Essa compactação também é verificada se ocorreu com sucesso (O arquivo existe, retorna 0), ou houve problema (o arquivo não foi criado, retorna 1).
 
 ```shell
       echo " - DUMP COMPACTADO " >> $LOG
       if [ ! -e  $BACKUP/$banco-$DATA.dmp.gz ]; then
              echo "$DATA - $banco -> Problemas com dump" >> $LOG
              let ErrosCompactacao++
              zabbix status.zip 1 [$banco]
       else
              zabbix status.zip 0 [$banco]
       fi
```


### backup.duracao
Duração do último backup. Cada backup tem seu tempo de execução medido. São disparados dois comandos ```date```, um no início e outro no final do dump. Após a execução do dump, é realizado um cálculo, onde obtemos o valor em segundos da duração do backup.

```shell
for banco in $databases; do
    InicioBackup=$( date +%s )
```
Após o comando do dump...
```shell
           TerminoBackup=$( date +%s )
           DuracaoBackup=$((TerminoBackup-InicioBackup))
```
E após o cálculo, o envio das informações ao server:
```shell
    zabbix duracao ${DuracaoBackup} [$banco]
```


### backup.duracao.zip
Duração da compactação do último backup. Semelhante ao item backup.duracao, porém medindo a duração da compactação:
```shell
            InicioCompactacaoBackup=$( date +%s )
            gzip -9 $banco-$DATA.dmp
            TerminoCompactacaoBackup=$( date +%s )
            DuracaoCompactacaoBackup=$((TerminoCompactacaoBackup-InicioCompactacaoBackup))
```
E com o valor setado na variável **DuracaoCompactacaoBackup**, podemos enviar para o server:
```shell
zabbix duracao.zip ${DuracaoCompactacaoBackup} [$banco]
```


### backup.tamanho
Tamanho do ultimo backup. Após as execuções dos dumps, medimos o seu tamanho.
```shell
           TamanhoBackup=$( wc -c < ${banco}-$DATA.dmp )
           zabbix tamanho ${TamanhoBackup} [$banco]           
```


### backup.tamanho.zip
Tamanho do ultimo backup compactado. Semelhante ao backup.tamanho, porém usando como referência o arquivo compactado.
```shell
           TamanhoBackupZip=$( wc -c < ${banco}-$DATA.dmp.gz )
           zabbix tamanho.zip ${TamanhoBackupZip} [$banco]
```


### backup.tamanho.total
Tamanho total dos últimos backups (todos os backups). Após a execução do backup e compactação de todas as bases, o tamanho total dos arquivos compactados é obtido e enviado ao zabbix server:
```shell
TamanhoTotalBackup=$( du -bsc *-${DATA}.dmp.gz | awk /total/'{ print $1}' )
zabbix tamanho.total ${TamanhoTotalBackup}
```


### backup.erros.dump
Total de erros na execução do backup. Caso ocorra uma falha no dump da base de dados, ela será contabilizada e enviada para o zabbix server, para que no final seja possível, de modo simples, saber quantos erros ocorreram durante aquela execução. Os erros são contabilizados pela variável ```ErrosDump```.
```shell
           if [ $Status != 0 ]; then
              echo "$ - Ocorreu algum erro durante o dump !!!" >>${LOG}
              let ErrosDump++
              zabbix status 1 [$banco]

```

### backup.erros.compactacao
Total de erros na compactação do backup. Semenhante ao backup.erros.dump, porém contabiliza os erros da compactação. Os erros são contabilizados pela variável ```ErrosCompactacao```.
```shell
       if [ ! -e  $BACKUP/$banco-$DATA.dmp.gz ]; then
              echo "$DATA - $banco -> Problemas com dump" >> $LOG
              let ErrosCompactacao++
              zabbix status.zip 1 [$banco]
```


### duracao.execucao
Duração total do backup. O tempo de execução do backup completo é monitorado, além do tempo de cada base individualmente. Logo no início do script, é declarada a variável ```InicioExecucao```, que será utilizada em um cálculo no final do script.
```shell
# Inicio do backup
InicioExecucao=$( date +%s )
```
Após a execução de todos dumps e compactações, é calculado o tempo total de duração do backup e enviado para o server:
```shell
TerminoExecucao=$( date +%s )
DuracaoExecucao=$((TerminoExecucao-InicioExecucao))
zabbix duracao.execucao ${DuracaoExecucao}
```


### tamanhodumps.total
Soma de todos os dumps sem compactação. Após cada dump realizado, seu tamanho é coletado pela variável ```TamanhoBackup```, e depois somado a variável ```TamanhoTotalBackups```:

Coleta do tamanho após o dump:
```shell
           mysqldump -h$SERVIDOR -u$USER -p$PASSWORD $banco --extended-insert --quick --routines --events --triggers >> $banco-$DATA.dmp
           Status=$( echo $?)
           TerminoBackup=$( date +%s )
           DuracaoBackup=$((TerminoBackup-InicioBackup))
           TamanhoBackup=$( wc -c < ${banco}-$DATA.dmp )
```
Antes do fim do `for`, o valor dessa variável é somada a variável `TamanhoTotalBackups`
```shell
    TamanhoTotalDumpsBackup=$((TamanhoTotalDumpsBackup+TamanhoBackup))

done
```
E já fora do laço, o valor do tamanho de todos os dumps é enviado para o server:
```shell
zabbix tamanhodumps.total $TamanhoTotalDumpsBackup
```

### database.size
Tamanho da base dentro do banco. Esse item atualmente funciona apenas para o MySQL, porém nada impede de que você crie a sua versão para PostgreSQL, Oracle, MSSQL ou outro. Antes do `for` iniciar com os dumps das bases, é executado um `select` dentro da base do MySQL, retornando o tamanho de cada base, e jogando essa saída em um arquivo (variável `TmpFile`). Quando o laço se inicia, ele verifica qual a base está sendo feito o backup e coleta o seu tamanho no arquivo.
```shell
# Exibe o tamanho total do banco de dados
mysql -u $USER -hlocalhost -p$PASSWORD -e \
'SELECT table_schema AS "Database",\
 ROUND(SUM(data_length + index_length)) \
 AS "Size (B)" \
 FROM information_schema.TABLES \
 GROUP BY table_schema;' > $TmpFile
```
A saída é algo do tipo:
```shell
cat /tmp/mysqlDatabasesSize.txt
Database        Size (B)
asterisk        47697920
asteriskcdrdb   324222976
gserv   212992
information_schema      180224
lacuna21        4292608
mysql   1185526
ocsweb  197798540
performance_schema      0
qstats  24871089
wordpress       1916928
```


E já dentro do `for`, após o dump da base:
```shell
          TamanhoBanco=$(awk /$banco/'{ print $NF }' $TmpFile )
          zabbix database.size ${TamanhoBanco} [$banco]
```

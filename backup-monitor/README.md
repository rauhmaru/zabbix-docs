O Backup monitor é utilizado para monitoramento de cada passo realizado pelo script de backup, fornecendo métricas e indicadores para acompanhamento de seu backup. Todos os valores são enviados via ```zabbix-sender```. Então, certifique-se de que ele está instalado.

# backup-monitor
## Funções existentes
* backup.status = Status do ultimo backup
* backup.status.zip = Status da compactação do ultimo backup
* backup.duracao = Duracao do ultimo backup
* backup.duracao.zip = Duracao da compactação do ultimo backup
* backup.tamanho = Tamanho do ultimo backup
* backup.tamanho.zip = Tamanho do ultimo backup compactado
* backup.tamanho.total = Tamanho total do ultimo backup (todos os backups)
* backup.erros.dump = Total de erros na execução do backup
* backup.erros.compactacao = Total de erros na compactação do backup
* duracao.execucao = Duração total do backup
* tamanhodumps.total = Soma de todos os dumps sem compactação


## Explicando o funcionamento
O script nesse repositório pode ser utilizado tranquilamente por você, porém caso queira apenas implementar no seu próprio script, você deverá ter atenção como funciona cada chave para não obter resultados vazio ou incorretos.

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
Status da compactacao do ultimo backup. Após o dump, é realizada a compactação do dump, para redução do seu tamanho. Essa compactação também é verificada se ocorreu com sucesso (O arquivo existe, retorna 0). ou houve problema (o arquivo não foi criado, retorna 1).
 
 ```shell
       echo " - DUMP COMPACTADO " >> $LOG
       if [ ! -e  $BACKUP/$banco-$DATA.dmp.gz ]; then
              echo "$DATA - $banco -> Problemas com dump" >> $LOG
              let ErrosCompactacao++
              zabbix status.zip 1 [$banco]
       else
              zabbix status.zip 0 [$banco]
              echo "  $banco - Tamanho COMPACTADO :  $( du -sh $banco-$DATA.dmp.gz )" >> $LOG
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
Duração da compactação do último backup. Semelhante ao item backup.duracao, porém medindo a compactação:
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
Tamanho do ultimo backup

### backup.tamanho.zip
Tamanho do ultimo backup compactado

### backup.tamanho.total
Tamanho total do ultimo backup (todos os backups)

### backup.erros.dump
Total de erros na execucao do backup

### backup.erros.compactacao
Total de erros na compactacao do backup

### duracao.execucao
Duração total do backup

### tamanhodumps.total
Soma de todos os dumps sem compactação

# Zabbix Template - Data Protector
O software Micro Focus Data Protection oferece backup e recuperação de dados em ambientes físicos, virtuais e híbridos.

## O Template
- Criado e testado no Zabbix 4.2
- Data Protector A.09.00
- CentOS 7

## Instalação
Crie o arquivo `/etc/zabbix/zabbix.d/userparameter_dp.conf` no host onde está instalado o Data Protector e reinicie o serviço:

```bash
service zabbix-agent restart
```

Nosso template precisa do resultado de alguns comandos que possuem execução restrita. Para que funcione, precisamos permitir via sudo.
Edite o arquivo `/etc/sudoers`:

Adicione o trecho 
```
## Data Protector
Cmnd_Alias DP = /opt/omni/sbin/utilns/get_info, /opt/omni/bin/omnimm, /opt/omni/sbin/omnidbcheck
zabbix ALL=(ALL) NOPASSWD:DP
```

Crie o diretório `/scripts`, com os arquivos `dp_discovery_dcbf.sh` e `dp_discovery_pools.sh`


## Itens
### Applications
#### DP Cell Info
O número de agentes com o Data Protector.
| Nome do item        | Chave           | Tipo  | 
| :------------------ |:---------------|:-------|
| Number of host agents  | dp.number.agents	  | Zabbix Agent  | DP Cell Info |


#### DP Database info
O item verifica se o arquivo `/tmp/omnirpt_rpt_dbsize.out` foi gerado. Os dados contidos nesse arquivo serve para alimentar outros itens deste template.
| Nome do item        | Chave           | Tipo  | 
| :------------------ |:---------------|:-------|
| Status of database report generator      | dp.report.db_size | Zabbix Agent |


#### DP IDB Consistency Check
Verificação de vários itens da base interna de consistência.
| Nome do item        | Chave           | Tipo  | 
| :------------------ |:---------------|:-------|
| IDB Consistency Check raw | dp.idb.consistency.check.raw	| Agente Zabbix | 
| IDB Database connection | dp.idb.consistency.check.db.conn | Item dependente | 
| IDB Database consistency | dp.idb.consistency.check.db.consist | Item dependente  |
| IDB DCBF(presence and size) | dp.idb.consistency.check.dcbf  | Item dependente  | 
| IDB Media consistency | dp.idb.consistency.check.media.consist  |  Item dependente |
| IDB OMNIDC(consistency) | dp.idb.consistency.check.omnidc  | Item dependente |
| IDB Schema consistency | dp.idb.consistency.check.schema | Item dependente |
| IDB SIBF(readability) |  dp.idb.consistency.check.sibf | Item dependente |


#### DP Services
Serviços necessários para o pleno funcionamento do Data Protector
| Nome do item        | Chave           | Tipo |
| :------------------ |:---------------|:------|
| Media Management Daemon (MMD) status | dp.service.status[mmd] | Zabbix Agent |
| Key Management Server (KMS) status | dp.service.status[kms] | Zabbix Agent |
| DP Internal Database (HPDP-IDB) status | dp.service.status[hpdp-idb] | Zabbix Agent |
|	DP scheduled backups (omnitrig) status | dp.service.status[omnitrig] | Zabbix Agent |
| DP Catalog Protection (HPDP-IDB-CP) status | dp.service.status[-cp]		| Zabbix Agent |
| DP Application Server (HPDP-IDB-AS) status | dp.service.status[-as]	| Zabbix Agent |

#### DP Sessions
Informações sobre as últimas sessões do Data Protector, tais como sessões abortadas, falhas, completas, erros nos agentes de disco, falhas no agente de mídia, tamanho total da sessão, etc.
| Nome do item        | Chave           | Tipo |
| :------------------ |:---------------|:------|
|	DP Last session reports data |dp.lastsession.report | Zabbix Agent |
| Last session aborted disk agents | dp.lastsession.report.aborteddiskagents |Item dependente	|
| Last session completed disk agents | dp.lastsession.report.completeddiskagents |Item dependente	|
| Last session disk agent errors total | 	dp.lastsession.report.diskagenterrorstotal |Item dependente	|
| Last session failed disk agents | dp.lastsession.report.faileddiskagents |Item dependente	|
| Last session failed media agents | dp.lastsession.report.failedmediaagents |Item dependente	|
| Last session media agents total | dp.lastsession.report.mediaagentstotal |Item dependente	|
| Last session total size | dp.lastsession.report.mbytestotal |Item dependente	|
| Last session ID | dp.lastsession["1"]	 | Zabbix Agent |
| Last session type | dp.lastsession["2"]	 | Zabbix Agent |
| Last session status | dp.lastsession["3"]	 | Zabbix Agent |
| Last session user.group@Host | dp.lastsession["4"]	 | Zabbix Agent |

## Triggers
| Nome da trigger      | Severidade  | Expressão           |  Descrição |
| :------------------- |:------------|:--------------------|:-----|
| DP backup was finished with errors| Attention | {Template Data Protector:dp.lastsession["3"].str("Completed/Errors")}=1 |  Quando uma sessão de backup é executada e ocorre alguma falha em pelo menos um agente (host) de backup. |
| DP backup was finished with failures | Attention | {Template Data Protector:dp.lastsession["3"].str("Completed/Failures")}=1 | Quando uma sessão de backup é iniciada e não é possível a execução um ou mais agentes (host) de backup.|
| DP Session backup failed | Attention | {Template Data Protector:dp.lastsession["3"].str(Failed)}=1 | Quando uma sessão de backup é iniciada e não é possível a sua execução. |
| Service HPDP-IDB-CP is not running | High | {Template Data Protector:dp.service.status[-cp].str(Active)}=0 | |
| Service HPDP-IDB is not running | High | 	{Template Data Protector:dp.service.status[hpdp-idb].str(Active)}=0 | |
| Service HPDP Application Server is not running | High | {Template Data Protector:dp.service.status[-as].str(Active)}=0 | |
| Service HPDP KMS is not running | High | 	{Template Data Protector:dp.service.status[kms].str(Active)}=0	 | |
| Service HPDP MMD is not running | High | {Template Data Protector:dp.service.status[mmd].str(Active)}=0 | |
| Service HPDP omnitrig is not running | High | 	{Template Data Protector:dp.service.status[omnitrig].str(Active)}=0 | |

## Gráficos
- Last session backup size: Shows:
  - Last session total size
  
- Last session information: Shows:
  - Last session aborted disk
  - Last session completed disk
  - Last session disk agent errors
  - Last session failed disk
  - Last session failed media

## Regras de descoberta
Existem duas regras de descoberta de baixo nível, e cada uma utiliza um script que existe nesse repositório (`dp_discovery_dcbf.sh` e `dp_discovery_pools.sh`)
| Nome da regra      | Chave  |
| :----------------- |:-------|
| DCBF discovery | dp.discovery.dcbf |
| Pools discovery | dp.discovery.pools	|

### DCBF discovery itens
O "Detail Catalog Binary Files" (DCBF) é o local que armazena parte das informações dos arquivos. Informações usadas pelo backup como tamanho, data de modificação, atributos, proteção, etc.
| Nome do item      | Chave  | Tipo |
| :----------------- |:-------|:-----|
|{#DCBF} size (%)	| dp.dcbf.dir["{#DCBF}"] | Zabbix Agent |

### Pools discovery itens
Faz um inventário do pool de mídias. Retorna dados importantes, como o estado das fitas, blocos utilizados, total de blocos, tipo de mídia, política do pool, etc.
| Nome do item       | Chave  | Tipo |
| :----------------- |:-------|:-----|
| [{#POOLNAME}] Pool raw data | dp.pool.raw["{#POOLNAME}"]	| Zabbix Agent |
| [{#POOLNAME}] Poor media | dp.pool.raw.media.poor.media["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Fair media | dp.pool.raw.media.fair.media["{#POOLNAME}"]  |	Item dependente |
| [{#POOLNAME}] Blocks used |	dp.pool.raw.pool.blocks.used["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Free pool support |	dp.pool.raw.free.pool.support["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Magazine support |	dp.pool.raw.magazine.support["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Blocks total |	dp.pool.raw.pool.blocks.total["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Maximum overwrites |	dp.pool.raw.media.maximum.overwrites["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Pool Description |	dp.pool.raw.pool.description["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Media type |	dp.pool.raw.media.type["{#POOLNAME}"]  |	Item dependente |
| [{#POOLNAME}] Pool Policy |	dp.pool.raw.pool.policy["{#POOLNAME}"] |	Item dependente |
| [{#POOLNAME}] Altogether media | dp.pool.raw.pool.altogether.media["{#POOLNAME}"]	 |	Item dependente |
| [{#POOLNAME}] Medium age limit |	dp.pool.raw.media.medium.age.limit["{#POOLNAME}"] |	Item dependente |



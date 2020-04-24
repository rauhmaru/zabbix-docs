# Zabbix Template - Data Protector
O software Micro Focus Data Protection oferece backup e recuperação de dados em ambientes físicos, virtuais e híbridos.

## O Template
- Criado e testado no Zabbix 4.2
- Data Protector A.09.00
- CentOS 7

## Itens
### Applications
#### DP Cell Info
| Nome do item        | Chave           | Tipo  | 
| ------------------- |:---------------|:-------|
| Number of host agents  | dp.number.agents	  | Zabbix Agent  | DP Cell Info |


#### DP Database info
| Nome do item        | Chave           | Tipo  | 
| ------------------- |:---------------|:-------|
| Status of database report generator      | dp.report.db_size | Zabbix Agent |


#### DP IDB Consistency Check
| Nome do item        | Chave           | Tipo  | 
| ------------------- |:---------------|:-------|
| IDB Consistency Check raw | dp.idb.consistency.check.raw	| Agente Zabbix | 
| IDB Database connection | dp.idb.consistency.check.db.conn | Item dependente | 
| IDB Database consistency | dp.idb.consistency.check.db.consist | Item dependente  |
| IDB DCBF(presence and size) | dp.idb.consistency.check.dcbf  | Item dependente  | 
| IDB Media consistency | dp.idb.consistency.check.media.consist  |  Item dependente |
| IDB OMNIDC(consistency) | dp.idb.consistency.check.omnidc  | Item dependente |
| IDB Schema consistency | dp.idb.consistency.check.schema | Item dependente |
| IDB SIBF(readability) |  	dp.idb.consistency.check.sibf | Item dependente |


#### DP Services
| Nome do item        | Chave           | Tipo |
| ------------------- |:---------------|:------|
| Media Management Daemon (MMD) status |  dp.service.status[mmd] | Zabbix Agent |
| Key Management Server (KMS) status |  dp.service.status[kms] | Zabbix Agent |
| DP scheduled backups (omnitrig) status | dp.service.status[omnitrig] | Zabbix Agent |
| DP Internal Database (HPDP-IDB) status | dp.service.status[hpdp-idb] | Zabbix Agent |
|	DP scheduled backups (omnitrig) status | dp.service.status[omnitrig] | Zabbix Agent |
| Key Management Server (KMS) status | dp.service.status[kms]	| Zabbix Agent |
| Media Management Daemon (MMD) status | dp.service.status[mmd]	| Zabbix Agent |

#### DP Sessions
| Nome do item        | Chave           | Tipo |
| ------------------- |:---------------|:------|
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
| -------------------- |:------------|:--------------------|:-----|
| DP backup was finished with errors| Attention | {Template Data Protector:dp.lastsession["3"].str("Completed/Errors")}=1 |  Quando uma sessão de backup é executada e ocorre alguma falha em pelo menos um agente (host) de backup. |

# Zabbix Template - Data Protector
O software Micro Focus Data Protection oferece backup e recuperação de dados em ambientes físicos, virtuais e híbridos.

## O Template
- Criado e testado no Zabbix 4.2
- Data Protector A.09.00
- CentOS 7

## Itens
### Aplications
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
| ------------------- |:---------------|-------|
| Media Management Daemon (MMD) status |  dp.service.status[mmd] | Zabbix Agent  |
| Key Management Server (KMS) status |  dp.service.status[kms] | Zabbix Agent  |
| DP scheduled backups (omnitrig) status | dp.service.status[omnitrig] | Zabbix Agent  |
| DP Internal Database (HPDP-IDB) status	 |  dp.service.status[hpdp-idb] | Zabbix Agent  |

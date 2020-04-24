# Zabbix Template - Data Protector
O software Micro Focus Data Protection oferece backup e recuperação de dados em ambientes físicos, virtuais e híbridos.

## O Template
- Criado e testado no Zabbix 4.2
- Data Protector A.09.00
- CentOS 7

## Itens
### Aplication

| Nome do item        | Chave           | Tipo  | Aplicação |
| ------------------- |:---------------:|-------|:---------:| 
| Number of host agents  | dp.number.agents	  | Zabbix Agent  | DP Cell Info |
| Status of database report generator      | dp.report.db_size | Zabbix Agent | DP Database info |
| IDB Consistency Check raw | dp.idb.consistency.check.raw	| Agente Zabbix | DP IDB Consistency Check |
| IDB Database connection | dp.idb.consistency.check.db.conn | Item dependente | DP IDB Consistency Check |
| IDB Database consistency | dp.idb.consistency.check.db.consist | Item dependente  | DP IDB Consistency Check |
| IDB DCBF(presence and size) | dp.idb.consistency.check.dcbf  | Item dependente  | DP IDB Consistency Check |
|  |   |   |  |
| Media Management Daemon (MMD) status | dp.service.status[mmd]	  | Zabbix Agent  |  |
| Last session user.group@Host | dp.lastsession["4"]  |   |  |
|  |   |   |  |
|  |   |   |  |
|  |   |   |  |
|  |   |   |  |
|  |   |   |  |

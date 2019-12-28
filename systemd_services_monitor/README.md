# systemd linux services
Monitoramento de serviços do Linux, indicado para hosts baseados em systemd
![systemd](zabbix_systemd.png)

## Motivação
Após fazer o [Template para o sysV](https://github.com/rauhmaru/sysv_services_monitor), o systemd também merece ser dignamente monitorado.

## Configuração
### No host
Crie o diretório `/scripts` e mova os scripts [service_status.sh](./service_status.sh) e [service_discovery.sh](./service_discovery.sh) para ele. Não esqueça da permissão de execução:

```shell
git clone https://github.com/rauhmaru/sysv_services_monitor.git
mkdir /scripts
cp sysv_services_monitor/service_* /scripts
chmod +x /scripts service_*
```

Em seguida, coloque o arquivo [userparameter_services.conf](./userparmeter_services.conf) no diretório de configurações do Zabbix Agent. Caso tenha instalado via gerenciador de pacote (yum, apt, zypper, etc.), ele estará no diretório `/etc/zabbix/zabbix_agentd.d/`, e em seguida, reinicie o serviço do zabbix_agent:

```shell
cp sysv_services_monitor/userparameter_systemd.conf /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent
```

### No Zabbix Server
Importe o [template linux systemd services](./template_linux_systemd_services.xml) para o seu Zabbix Server e em seguida, adicione no servidor que deseja monitorar os serviços.


### Observações importantes

## Rerefências
* 

# systemd linux services
Monitoramento de serviços do Linux, indicado para hosts baseados em systemd
![systemd](zabbix_systemd.png)

## Motivação
Após fazer o [Template para o sysV](https://github.com/rauhmaru/sysv_services_monitor), o systemd também merece ser dignamente monitorado.

## Configuração
### No host
Crie o diretório `/scripts` e mova os scripts para dentro. Não esqueça da permissão de execução:

```shell
git clone https://github.com/rauhmaru/sysv_services_monitor.git
mkdir /scripts
cp zabbix-docs/systemd-services-monitor/systemd_* /scripts
chmod +x /scripts systemd_*
```

Em seguida, coloque o arquivo [userparameter_systemd.conf](./userparmeter_systemd.conf) no diretório de configurações do Zabbix Agent. Caso tenha instalado via gerenciador de pacote (yum, apt, zypper, etc.), ele estará no diretório `/etc/zabbix/zabbix_agentd.d/`, e em seguida, reinicie o serviço do zabbix_agent:

```shell
cp zabbix-docs/systemd-services-monitor/userparameter_systemd.conf /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent
```

### No Zabbix Server
Importe o [template linux systemd services](./template_linux_systemd_services.xml) para o seu Zabbix Server e em seguida, adicione no servidor que deseja monitorar os serviços.


### Observações importantes

## Rerefências
* 

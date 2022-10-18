# Playbooks

## Verzeichnisstruktur
 
Das Haupt-Playbook **_vodafone.yml_** importiert weitere Playbooks, es enthält ansonsten keine eigenen Plays. Alle importierten Playbooks werden im Ordner **_playbooks_** im Projekt-Verzeichnis hinterlegt.
 
```
.
├── ansible.cfg
├── group_vars
├── host_vars
├── playbooks
├── roles
├── inventory
├── README.md
└── vodafone.yml
```
 
> Die Speicherung der importierten Playbooks im **_playbooks_**-Ordner hat zur Folge, dass Rollen nicht mehr gefunden werden bei der Ausführung der **_vodafone.yml_**.  
> Eine lokale **_ansible.cfg_** mit Parameter **_role\_path=roles_** ist notwendig.
 
<p>
<details>
<summary><b>Beispiele</b></summary>
 
Die folgenden Beispiele verdeutlichen die Konventionen zu Playbooks:  
 
**Main Playbook**
```yaml
# Main Vodafone Playbook
 
- import_playbook: playbooks/kafka-servers.yml
- import_playbook: playbooks/streamproc-servers.yml
 
```
 
**Lower level Playbook**
```yaml
# This Playbook installs Kafka Servers with Zookeeper
 
- hosts: kafka_servers
  roles:
    - nom-kafka
```
 
</details>
</p>
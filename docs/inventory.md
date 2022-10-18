# Inventory

## Multiple inventory files

# Ansible Style Guide
Dieser Guide soll als allgemein gültige Konvention bei der Erstellung der Ansible Playbooks genutzt werden.

## Allgemein

Dateiname aus mehrere Wörtern werden mit Bindestrichen getrennt.
YAML-Dateien werden mit der Endung **_.yml_** gespeichert.  
Im folgenden wird näher auf die zu verwendende YAML Syntax eingegangen.
 
## YAML Syntax
 
Es werden zwei Leerzeichen zur Einrückung von Listenelementen verwendet:
 
```yaml
- hosts: n2servers
  roles:
    - distribute-18.2
    - common
```
 
```yaml
ntp_server_list:
  - "10.13.96.40"
  - "10.14.32.40 "
  - "10.15.96.40"
  - "10.14.224.40"
  - "10.13.224.40"
```
 
Die sogenannte YAML "One-Line"-Syntax wird nicht verwendet, weder bei der Übergabe von Parameter in Tasks, noch für Listen oder Dictionaries.
 
### Beispiele
 
**Task mit One-Line-Syntax**
```yaml
# One-Line Syntax should not be used
- name: Ensure Ansible is installed with Python package manager
  pip: name=ansible state=present
```
 
**Task mit Liste in One-Line-Syntax**
```yaml
# One-Line Syntax should not be used
- name: Ensure Ansible and dependencies are installed with Python package manager
  pip:
    name: "{{ item }}"
    state: present
  loop: ['ansible-base', 'ansible', 'ansible-lint']
``` 
 
Auskommentierter Code ist generell zu vermeiden. Playbooks oder Taskfiles werden nicht commited, falls sie auskommentieren Code beinhalten.  
Zu lange Zeilen sind zu vermeiden, maximal 70 Zeichen sind erlaubt. Längere Zeilen müssen über einen _YAML Folded Scalar_ (">") aufgebrochen werden.
 
<p>
<details>
<summary><b>Beispiele</b></summary>
 
**Task mit zu langer Zeile**
```yaml
# Task with too long line, also does not work idempotent
- name: Execute Python command
  command:
    cmd: python a very long command --with=very --long-options=foo --and-even=more_options --like-these
```
 
**Task mit YAML folded scalar**
```yaml
# Task still does not work idempotent, but line length is ok
- name: Execute Python command
  command:
    cmd: >
      python a very long command --with=very --long-options=foo
      --and-even=more_options --like-these
```
 
</details>
</p>
 
## Inventory
 
Es werden unterschiedliche Inventories verwendet, alle Inventory-Dateien werden im Ordner **_inventory_** hinterlegt.  
Gruppen im Inventory werden in der folgenden Reihenfolge definiert:
 
1. Parent
2. Children
3. Parent-Variablen
4. Child-Variablen
 
<p>
<details>
<summary><b>Beispiele</b></summary>
 
```yaml
[kafka_servers:children]
kafka_servers_site1
kafka_servers_site2
 
[kafka_servers_site1]
ts4dnsdm001
ts4dnsdm002
ts4dnsdm003
 
[kafka_servers_site2]
ts4dnsdm051
ts4dnsdm052
ts4dnsdm053
 
[kafka_servers:vars]
nom-kafka_version=19.1.1.0-233956
 
[dns_servers]
dns9-i.vflab.de
dns10-i.vflab.de
```
 
</details>
</p>
 
## Playbooks
 
Ein Ansible Playbook enthält immer ein (oder mehrere) Plays in einer YAML Liste oder importiert weitere Playbooks über das _import\_playbook_-Statement.  
Jedes Play referenziert eine (oder mehrere) Gruppen aus dem Inventory über den _hosts_ Parameter. Ein Play
 
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
 
## Rollen
 
Neue Playbook-Funktionalität wird immer in einer Rolle hinzugefügt oder einer bereits bestehenden Rolle, falls diese Rolle den gleichen Zweck erfüllt.
Rollen sollen nur einem festgelegten und durch den Rollen-Namen eindeutigen Zweck erfüllen.  
Jede Rolle wird nach dem Ansible Galaxy Stil angelegt: `ansible-galaxy role init <Rollen Name>`. Nicht genutzte Ordner und Dateien verbleiben in der gegebenen Struktur.
Der Rollenname soll kurz und eindeutig sein. Er wird mit Bindestrichen getrennt, falls er aus mehreren Wörtern besteht.
 
Die README der Rolle muss befüllt sein. Die folgenden Unterpunkte müssen befüllt werden:

* **Title**
  * kurze Aufgabenbeschreibung der Rolle
  * evtl. kurze Beschreibung der ausgerollten Applikation
  * optional: Übersicht über Rollenstruktur (tree)
* **Requirements**
  * spezielle (Python-) Pakete z.B. netaddr
  * eigene Module oder Plugins z.B. nom_tell-Modul
* **Role Variables**
  * verwendete Variablen in Tabelle, idealerweise in der Reihenfolge des Auftretens
    * _Variable name_
    * _Type_: String, Integer, Float, Boolean, List, Dictionary
    * _Default Value_: Wert aus default/main.yml, oder _None_, falls nicht gesetzt
    * _Description_: ausführliche Beschreibung und Ort der Variablendefinition, wenn außerhalb der Rolle (z.B. group_vars/host_vars)
* **Dependencies**
  * Liste mit Rollen, welche zuvor erfolgreich gelaufen sein müssen
* **Tags**
  * Liste mit Tags, falls verwendet
* **Example Playbook**
  * minimales Playbook zur Ausführung der Rolle
* **Author Information**
  * Autor(en) inklusive Vodafone E-Mail-Adresse

<p>
<details>
<summary><b>Beispiel</b></summary>

    # nom-vkms-controller

    The role sets up the nom-vkms service.   
    The Vault Key Management System (vkms) manages secrets and is used to generate and distribute certificates in support of secure communication between SPS components.

    ## Requirements

    None.

    ## Role Variables

    The role defines the following variables:

    Variable Name | Type | Default Value | Description
    ------------- | ---- | ------------- | -----------
    nom_vkms_secrets_dir | String | /var/nom/secrets/nom-vkms | The directory where all certificates and keys are stored.
    nom_vkms_ca_ttl_days | String | 3560 | The amount of days the CA certificate is valid.
    nom_vkms_https_cert_cn | String | nom-vkms | The common name of the certificate.
    nom_vkms_client | String | /usr/local/nom/sbin/nom-vkms-client | The path to to nom-vkms client binary.
    nom_vkms_root_ttl_hours | String | 87600h | The amount of hours the root certificate is valid.
    nom_vkms_intermediate_ttl_hours | String | 35040h | The amount of hours the intermediate certificate is valid.
    nom_vkms_leaf_ttl_hours | String | 8760h | The amount of hours the leaf certificate is valid.

    ## Dependencies

    This role expects to run **after** the following roles:
    * repository
    * networking
    * common
    * software

    ## Tags

    The role can be executed with the following tags:
    * nom-vkms-controller
    * install
    * configure
    * init
    * unseal
    * ca-certificate

    ## Example Playbook

    Use the role in a playbook like this (after running plays/roles from dependencies section):
    ```yaml
    - name: Execute nom-vkms role
      hosts: vkms_servers
      become: yes
      roles:
        - nom-vkms-controller
    ```

    ## Author Information

    Tim Grützmacher - <tim.gruetzmacher@vodafone.com>

</details>
</p>

## Tasks
 
Die folgenden Konvention müssen bei der Erstellung von Tasks beachtet werden:
* **Struktur**  
Logisch zusammengehörige Tasks sollen in einzelne Dateien ausgelagert werden. Die **_main.yml_** der Rolle importiert dann lediglich die Task-Dateien. Die Dateinamen der Task-Dateien sollten eindeutig den Zweck beschreiben.  
* **Benamung**  
Jeder Task muss eine aussagekräftige Beschreibung im **_name_**-Parameter in Satzform haben.
* **Dokumentation**  
Code-Dokumentation zu einem Task ist erwünscht, falls weitere Informationen zur Arbeitsweise notwendig sein sollte, welche nicht bereits durch den _name_-Parameter erklärt wird. Dazu gehören komplexe Filter-Ausdrücke, multiple Bedingungen oder anderes.
* **Idempotenz**  
Jeder Task muss idempotent sein, werden nicht idempotente Module verwendet (command, shell, raw) müssen diese Tasks über entsprechende Parameter oder Konditionen zu einer idempootenten Arbeitsweise entwickelt werden. Es soll generell der Einsatz von nicht-idempotenten Modulen auf ein notwendiges Minimum reduziert werden. 
* **Check Mode**  
Jeder Task muss im Check-Mode ausführbar sein.
 
<p>
<details>
<summary><b>Beispiele</b></summary>
 
Die folgenden Beispiele verdeutlichen die Konventionen zu Playbooks:  
 
**Ausführlich beschriebener Task mit korrekter Einrückung**
```yaml
- name: Ensure boom groups exists
  group:
    name: "{{ item }}"
    state: present
  with_items:
    - boomuser
    - boomgrp
```
 
**Kommentierter Task**
```yaml
# Besseres Beispiel finden
- name: Install required Influxdb packages for RHEL6 and derivates from package store
  yum:  
    state: present
    name:
     - nom-influxdb-1.7.9
  when: ( n2_exact_version is not defined or
          ( n2_exact_version is defined and 
            n2_exact_version == "19.1.0.0") ) and 
        ( ansible_distribution == "CentOS"  or
          ansible_distribution == "RedHat"  or 
          ansible_distribution == "OracleLinux" )
 
```
 
</details>
</p>
 
## Variablen
 
Die folgenden Konventionen gelten bei der Benamung von Variablen:

* Jinja2 Syntax verwenden: `{{ var }}`
  * Leerzeichen vor und hinter der Variablen
* so kurz wie möglich, so ausführlich wie nötig
* Kleinschreibung
* Wörter durch Unterstriche getrennt
* komplexe Variablen mit _\_type_-Endung
  * Dictionaries: **_\_dict_**
  * Listen: **_\_list_**
* Werte nach Möglichkeit in Anführungszeichen (Strings)
* Boolean Werte in Kleinschreibung (true, false)
  * folgende Schreibweisen vermeiden: True, TRUE, yes, False, FALSE, no
 
Beinhaltet eine Variable einen Pfad, wird kein hinterer Schrägstrich verwendet. 
 
<p>
<details>
<summary><b>Beispiele</b></summary>
 
**Variable mit Pfad**
```yaml
nominum_package_directory: "/dat/software"
```
 
**Variable mit Pfad**
```yaml
my_path: "/tmp"
foo: "{{ my_path }}/bar.txt"
```
 
**Variable mit Liste**
```yaml
ntp_server_list:
  - "10.13.96.40"
  - "10.14.32.40 "
  - "10.15.96.40"
  - "10.14.224.40"
  - "10.13.224.40"
 
```
 
**Variable mit Dictionary**
```yaml
backup_server_dict:
  server:
    domain: dmz.vfd2.de
    primary:
      name: ts4vs1sv301b38
      address: 2a01:08f0:fffe:1000:0000:0000:0000:000a
    secondary:
      name: ts4vs1sv303
      address: 2a01:08f0:fffe:1000:0000:0000:0000:000b
 
```
 
**Boolean Variable**
```yaml
telemetry_enable: true
```
 
</details>
</p>
 
Variablen werden nur an den folgenden Orten definiert:

* group_vars
* host_vars
* defaults-Ordner (innerhalb von Rollen)
 
Die Definition von Variablen an abweichenden Stellen muss abgestimmt und in der README kenntlich gemacht werden!
 
Bei der Verwendung von Variablen in Playbooks und Tasks gelten folgende Konventionen:

* Leerzeichen vor **und** hinter der Variablen innerhalb der doppelten geschweiften Klammern.
 
## Tags
 
Tags sind sparsam zu verwenden. Tags sind lediglich für Rollen und für importierte Tasks innerhalb der main.yml einer Rolle erlaubt. Tags auf Task-Ebene sind darüber hinaus nicht erlaubt.

## Sensible Daten
 
Die folgenden Daten im Playbook müssen Vault-verschlüsselt werden:
 
* Usernamen
* Public Keys
* Passwörter
* API Tokens
 
Vault-verschlüsselte Variablen werden folgendermaßen hinterlegt: **TODO**

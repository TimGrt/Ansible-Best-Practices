# Roles

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


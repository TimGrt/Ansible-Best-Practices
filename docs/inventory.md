# Inventory

## Multiple inventory files


 
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

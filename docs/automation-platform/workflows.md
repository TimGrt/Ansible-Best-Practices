# Workflows

[Workflows](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html/using_automation_execution/controller-workflow-job-templates){:target="_blank"}  link together a sequence of disparate resources like [Job templates](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html/using_automation_execution/controller-job-templates){:target="_blank"}, other Workflow job templates, [Project syncs](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html/using_automation_execution/controller-projects){:target="_blank"} or [Inventory source syncs](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html/using_automation_execution/controller-jobs#controller-inventory-sync-jobs_jobs-in-controller){:target="_blank"}.

## Variables across workflow steps

Transferring information across workflow steps can't be done by the `set_fact` module, these facts are only available during a normal playbook run. Workflow job template run separate Jobs targeting separate playbooks.

!!! quote "Possible Use-case"
    Think of a first workflow step searching for an available IP address in an IPAM tool. The second workflow step can't know this IP before the workflow itself starts, therefore this information needs to be transferred from the first workflow step to the second one.

In addition to the workflow `extra_vars`, jobs ran as part of a workflow can inherit variables in the *artifacts* dictionary of a parent job in the workflow. These artifacts can be defined by the [`set_stats` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/set_stats_module.html){:target="_blank"}.

!!! info
    The point of set_stats in workflows is to have a vehicle to pass data via `--extra-vars` to the next job template.

### Setting stats

The first playbook (Job Template) in the workflow run defines a variable in the `data` dictionary.

```yaml title="Task of playbook in Workflow node 1"
--8<-- "example-set-stats-task.yml"
```

!!! bug
    Do **not** use the `per_host` parameter, it breaks the artifacts gathering!  
    You can't provide distinct stats per host (without workarounds).

### Retrieving stats

The second playbook (Job Template) in the workflow run references the variable of the `data` dictionary.

```yaml title="Task of playbook in Workflow node 2"
--8<-- "example-debug-stats-task.yml"
```

### Display custom stats

Custom stats can be displayed at the playbook recap, you must set `show_custom_stats` in the `#!ini [defaults]` section of your Ansible configuration file:

```ini title="ansible.cfg"
[defaults]
show_custom_stats = true
```

Defining the environment variable `ANSIBLE_SHOW_CUSTOM_STATS` and setting to `true` achieves the same behavior.

??? example "Play recap with custom stats"

    ``` { .console .no-copy }

    PLAY RECAP *********************************************************************
    localhost                  : ok=13    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

    CUSTOM STATS: ******************************************************************
        RUN: { "available_ip": 10.28.13.5"}
    ```

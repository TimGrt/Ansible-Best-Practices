# Monitoring & Troubleshooting

This section describes different methods to monitor or troubleshoot your Ansible playbook runs.  
When you need metrics about playbook execution and machine resource consumption, [callback plugins](https://docs.ansible.com/ansible/latest/plugins/callback.html){:target="_blank"} can help you drill down into the data and troubleshoot issues.

## How long does it take?

To measure the time spent for tasks and the overall playbook run, multiple callback plugins are available.
Install the necessary collections which include the desired callback plugins:

```console
ansible-galaxy collection install ansible.posix
```

The following plugins are available and useful for different purposes.

* [ansible.posix.timer](https://docs.ansible.com/ansible/latest/collections/ansible/posix/timer_callback.html#ansible-collections-ansible-posix-timer-callback){:target="_blank"} - Adds **total play duration** to the play stats.
* [ansible.posix.profile_tasks](https://docs.ansible.com/ansible/latest/collections/ansible/posix/profile_tasks_callback.html#ansible-collections-ansible-posix-profile-tasks-callback){:target="_blank"} - For **timing individual tasks** and overall execution time.
* [ansible.posix.profile_roles](https://docs.ansible.com/ansible/latest/collections/ansible/posix/profile_roles_callback.html#ansible-collections-ansible-posix-profile-roles-callback){:target="_blank"} - Adds timing information to roles.

!!! tip
    To use the callback plugins, they need to be **enabled**.

For example, to show the start-time and duration for every task, you can use the `timer` and `profile_tasks` callback plugin.
Add the following block to your `ansible.cfg`:

```ini
[defaults]
callbacks_enabled = ansible.posix.timer, ansible.posix.profile_tasks
```

??? example "Example output"

    ```{ .console .no-copy .hl_lines='1'}
    $ ansible-playbook -i inventory.ini create_workshop_environment.yml

    PLAY [Create Workshop environment] ****************************************************************************************************

    TASK [Gathering Facts] ****************************************************************************************************************
    Saturday 07 September 2024  16:05:19 +0200 (0:00:00.004)       0:00:00.004 ****
    ok: [localhost]

    TASK [Get package facts] **************************************************************************************************************
    Saturday 07 September 2024  16:05:20 +0200 (0:00:00.836)       0:00:00.840 ****
    ok: [localhost]

    [...cut for readability...]

    PLAY RECAP ****************************************************************************************************************************
    localhost                  : ok=10   changed=6    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0  
    node1                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
    node2                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
    node3                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  

    Playbook run took 0 days, 0 hours, 0 minutes, 43 seconds
    Saturday 07 September 2024  16:06:03 +0200 (0:00:02.318)       0:00:43.633 ****
    ===============================================================================
    Install SSH daemon ------------------------------------------------------------------------------------------------------------ 25.25s
    Start managed node containers, publish 3 ports for each container -------------------------------------------------------------- 3.67s
    Gathering Facts ---------------------------------------------------------------------------------------------------------------- 2.92s
    Start SSH daemon --------------------------------------------------------------------------------------------------------------- 2.64s
    Add public key of workshop SSH keypair to authorized_keys of ansible user ------------------------------------------------------ 2.32s
    Remove /run/nologin to be able to login as unprivileged user ------------------------------------------------------------------- 2.20s
    Create OpenSSH keypair for accessing managed nodes ----------------------------------------------------------------------------- 1.38s
    Get package facts -------------------------------------------------------------------------------------------------------------- 0.84s
    Gathering Facts ---------------------------------------------------------------------------------------------------------------- 0.84s
    Pull image for managed node containers ----------------------------------------------------------------------------------------- 0.52s
    Create workshop inventory file ------------------------------------------------------------------------------------------------- 0.28s
    Deploy ansible.cfg to home directory ------------------------------------------------------------------------------------------- 0.19s
    Create folder for workshop inventory ------------------------------------------------------------------------------------------- 0.18s
    Add block to ssh_config for easy SSH access to managed nodes ------------------------------------------------------------------- 0.17s
    Check for existing SSH keypair ------------------------------------------------------------------------------------------------- 0.14s
    Install Podman ----------------------------------------------------------------------------------------------------------------- 0.03s
    Backup file of .ansible.cfg created -------------------------------------------------------------------------------------------- 0.02s
    Check if OpenSSH keypair does not match target configuration ------------------------------------------------------------------- 0.02s
    Abort playbook if keypair was found and does not match target configuration ---------------------------------------------------- 0.02s
    ```

## How much resources are consumed?

To measure system resources used by Ansible, you can use the following *callback plugins*, both are utilizing *cgroups*.

* [community.general.cgroup_memory_recap](https://docs.ansible.com/ansible/latest/collections/community/general/cgroup_memory_recap_callback.html){:target="_blank"} - profiles maximum memory usage of individual tasks and displays a recap at the end
* [ansible.posix.cgroup_perf_recap](https://docs.ansible.com/ansible/latest/collections/ansible/posix/cgroup_perf_recap_callback.html){:target="_blank"} - profiles system activity of Ansible and individual tasks and displays a recap at the end of the playbook execution.

*cgroups* (abbreviated from control groups) is a Linux kernel feature that limits, accounts for, and isolates the resource usage (CPU, memory, disk I/O, etc) of a collection of processes. You can use the *cgroup-tools* (for Fedora-based systems the package is called *libcgroup-tools*) utilities to create a *cgroup* profile and interact with cgroups.

!!! warning
    Installing `cgroup-tools` and creating the *cgroup*-profile requires *sudo* permissions.

Install the *cgroup-tools* which contains command-line programs, services and a daemon for manipulating control groups using the libcgroup library.

```console
sudo apt install cgroup-tools
```

Create a *cgroup* which includes the CPU Accounting, the memory (RAM) and the PIDs subsystem:

```console
sudo cgcreate -a ${USER}:${USER} -t ${USER}:${USER} -g cpuacct,memory,pids:ansible_profile
```

Install the necessary collections which include the desired callback plugins:

```console
ansible-galaxy collection install ansible.posix community.general
```

!!! tip
    To use the callback plugins, they need to be **enabled** and configured.

### Show RAM usage

To show the memory usage for every task, you can use the `cgroup_memory_recap` callback plugin.
Add the following block to your `ansible.cfg`:

```ini
[defaults]
callbacks_enabled = community.general.cgroup_memory_recap

[callback_cgroupmemrecap]
cur_mem_file = /sys/fs/cgroup/memory/ansible_profile/memory.usage_in_bytes
max_mem_file = /sys/fs/cgroup/memory/ansible_profile/memory.max_usage_in_bytes
```

The *cgexec* program executes a task command (in our case a playbook run) with arguments in given control groups (in our case the *memory* group only).

```console
cgexec -g memory:ansible_profile ansible-playbook playbook.yml
```

??? example "Example output"

    ```{ .console .no-copy }
    $ cgexec -g memory:ansible_profile ansible-playbook -i inventory.ini create_workshop_environment.yml

    PLAY [Create Workshop environment] ******************************************************

    TASK [Gathering Facts] ******************************************************************
    ok: [localhost]

    TASK [Get package facts] ****************************************************************
    ok: [localhost]

    [...cut for readability...]

    PLAY RECAP ******************************************************************************
    localhost                  : ok=10   changed=6    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0  
    node1                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
    node2                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
    node3                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  


    CGROUP MEMORY RECAP *********************************************************************
    Execution Maximum: 281.57MB

    Gathering Facts (299e2579-3d81-65cc-ccd9-00000000001f): 148.23MB
    Get package facts (299e2579-3d81-65cc-ccd9-000000000006): 220.73MB
    Install Podman (299e2579-3d81-65cc-ccd9-000000000007): 166.30MB
    Pull image for managed node containers (299e2579-3d81-65cc-ccd9-000000000008): 220.42MB
    Start managed node containers, publish 3 ports for each container (299e2579-3d81-65cc-ccd9-000000000009): 227.33MB
    Create folder for workshop inventory (299e2579-3d81-65cc-ccd9-00000000000a): 190.53MB
    Create workshop inventory file (299e2579-3d81-65cc-ccd9-00000000000b): 203.59MB
    Add block to ssh_config for easy SSH access to managed nodes (299e2579-3d81-65cc-ccd9-00000000000c): 192.20MB
    Deploy ansible.cfg to home directory (299e2579-3d81-65cc-ccd9-00000000000d): 185.89MB
    Backup file of .ansible.cfg created (299e2579-3d81-65cc-ccd9-00000000000e): 168.18MB
    Check for existing SSH keypair (299e2579-3d81-65cc-ccd9-00000000000f): 191.01MB
    Check if OpenSSH keypair does not match target configuration (299e2579-3d81-65cc-ccd9-000000000011): 168.10MB
    Abort playbook if keypair was found and does not match target configuration (299e2579-3d81-65cc-ccd9-000000000012): 168.20MB
    Create OpenSSH keypair for accessing managed nodes (299e2579-3d81-65cc-ccd9-000000000014): 210.39MB
    Gathering Facts (299e2579-3d81-65cc-ccd9-000000000060): 251.42MB
    Install SSH daemon (299e2579-3d81-65cc-ccd9-000000000017): 275.68MB
    Start SSH daemon (299e2579-3d81-65cc-ccd9-000000000018): 281.44MB
    Remove /run/nologin to be able to login as unprivileged user (299e2579-3d81-65cc-ccd9-000000000019): 250.57MB
    Add public key of workshop SSH keypair to authorized_keys of ansible user (299e2579-3d81-65cc-ccd9-00000000001a): 273.89MB
    ```

!!! tip
    Create an *alias* for the *cgexec...* part:

    !!! example "~/.bash_aliases"
        ```console
        alias ansible-playbook-profile='cgexec -g memory:ansible_profile ansible-playbook'
        ```

    First time usage requires `source ~/.bash_aliases`, now you can run:

    ```console
    ansible-playbook-profile -i inventory playbook.yml
    ```

### Show RAM, CPU & PIDs usage

To show the memory and CPU usage, as well as forked processes for every task, you can use the `cgroup_perf_recap` callback plugin.
Add the following block to your `ansible.cfg`:

```ini
[defaults]
callbacks_enabled = ansible.posix.cgroup_perf_recap

[callback_cgroup_perf_recap]
control_group = ansible_profile
```

The *cgexec* program executes a task command (in our case a playbook run) with arguments in given control groups.

```console
cgexec -g cpuacct,memory,pids:ansible_profile ansible-playbook playbook.yml
```

??? example "Example output"

    ```{ .console .no-copy }
    $ cgexec -g cpuacct,memory,pids:ansible_profile ansible-playbook -i inventory.ini create_workshop_environment.yml

    PLAY [Create Workshop environment] *****************************************************************************

    TASK [Gathering Facts] *****************************************************************************************
    ok: [localhost]

    TASK [Get package facts] ***************************************************************************************
    ok: [localhost]

    [...cut for readability...]

    PLAY RECAP *****************************************************************************************************
    localhost                  : ok=10   changed=6    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0  
    node1                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
    node2                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
    node3                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  


    CGROUP PERF RECAP **********************************************************************************************
    Memory Execution Maximum: 286.29MB
    cpu Execution Maximum: 302.46%
    pids Execution Maximum: 43.00

    memory:
    Gathering Facts (299e2579-3d81-800b-f0f1-00000000001f): 109.20MB
    Get package facts (299e2579-3d81-800b-f0f1-000000000006): 182.14MB
    Install Podman (299e2579-3d81-800b-f0f1-000000000007): 120.23MB
    Pull image for managed node containers (299e2579-3d81-800b-f0f1-000000000008): 216.32MB
    Start managed node containers, publish 3 ports for each container (299e2579-3d81-800b-f0f1-000000000009): 224.69MB
    Create folder for workshop inventory (299e2579-3d81-800b-f0f1-00000000000a): 159.62MB
    Create workshop inventory file (299e2579-3d81-800b-f0f1-00000000000b): 206.01MB
    Add block to ssh_config for easy SSH access to managed nodes (299e2579-3d81-800b-f0f1-00000000000c): 162.30MB
    Deploy ansible.cfg to home directory (299e2579-3d81-800b-f0f1-00000000000d): 162.27MB
    Backup file of .ansible.cfg created (299e2579-3d81-800b-f0f1-00000000000e): 162.33MB
    Check for existing SSH keypair (299e2579-3d81-800b-f0f1-00000000000f): 162.94MB
    Check if OpenSSH keypair does not match target configuration (299e2579-3d81-800b-f0f1-000000000011): 163.47MB
    Abort playbook if keypair was found and does not match target configuration (299e2579-3d81-800b-f0f1-000000000012): 166.45MB
    Create OpenSSH keypair for accessing managed nodes (299e2579-3d81-800b-f0f1-000000000014): 216.06MB
    Gathering Facts (299e2579-3d81-800b-f0f1-000000000060): 250.53MB
    Install SSH daemon (299e2579-3d81-800b-f0f1-000000000017): 271.96MB
    Start SSH daemon (299e2579-3d81-800b-f0f1-000000000018): 268.99MB
    Remove /run/nologin to be able to login as unprivileged user (299e2579-3d81-800b-f0f1-000000000019): 246.32MB
    Add public key of workshop SSH keypair to authorized_keys of ansible user (299e2579-3d81-800b-f0f1-00000000001a): 273.55MB

    cpu:
    Gathering Facts (299e2579-3d81-800b-f0f1-00000000001f): 92.82%
    Get package facts (299e2579-3d81-800b-f0f1-000000000006): 101.37%
    Install Podman (299e2579-3d81-800b-f0f1-000000000007): 0.00%
    Pull image for managed node containers (299e2579-3d81-800b-f0f1-000000000008): 77.08%
    Start managed node containers, publish 3 ports for each container (299e2579-3d81-800b-f0f1-000000000009): 82.08%
    Create folder for workshop inventory (299e2579-3d81-800b-f0f1-00000000000a): 0.00%
    Create workshop inventory file (299e2579-3d81-800b-f0f1-00000000000b): 101.61%
    Add block to ssh_config for easy SSH access to managed nodes (299e2579-3d81-800b-f0f1-00000000000c): 0.00%
    Deploy ansible.cfg to home directory (299e2579-3d81-800b-f0f1-00000000000d): 0.00%
    Backup file of .ansible.cfg created (299e2579-3d81-800b-f0f1-00000000000e): 0.00%
    Check for existing SSH keypair (299e2579-3d81-800b-f0f1-00000000000f): 0.00%
    Check if OpenSSH keypair does not match target configuration (299e2579-3d81-800b-f0f1-000000000011): 0.00%
    Abort playbook if keypair was found and does not match target configuration (299e2579-3d81-800b-f0f1-000000000012): 0.00%
    Create OpenSSH keypair for accessing managed nodes (299e2579-3d81-800b-f0f1-000000000014): 101.40%
    Gathering Facts (299e2579-3d81-800b-f0f1-000000000060): 144.79%
    Install SSH daemon (299e2579-3d81-800b-f0f1-000000000017): 302.46%
    Start SSH daemon (299e2579-3d81-800b-f0f1-000000000018): 245.07%
    Remove /run/nologin to be able to login as unprivileged user (299e2579-3d81-800b-f0f1-000000000019): 151.99%
    Add public key of workshop SSH keypair to authorized_keys of ansible user (299e2579-3d81-800b-f0f1-00000000001a): 175.70%

    pids:
    Gathering Facts (299e2579-3d81-800b-f0f1-00000000001f): 9.00
    Get package facts (299e2579-3d81-800b-f0f1-000000000006): 9.00
    Install Podman (299e2579-3d81-800b-f0f1-000000000007): 8.00
    Pull image for managed node containers (299e2579-3d81-800b-f0f1-000000000008): 21.00
    Start managed node containers, publish 3 ports for each container (299e2579-3d81-800b-f0f1-000000000009): 22.00
    Create folder for workshop inventory (299e2579-3d81-800b-f0f1-00000000000a): 9.00
    Create workshop inventory file (299e2579-3d81-800b-f0f1-00000000000b): 11.00
    Add block to ssh_config for easy SSH access to managed nodes (299e2579-3d81-800b-f0f1-00000000000c): 8.00
    Deploy ansible.cfg to home directory (299e2579-3d81-800b-f0f1-00000000000d): 12.00
    Backup file of .ansible.cfg created (299e2579-3d81-800b-f0f1-00000000000e): 9.00
    Check for existing SSH keypair (299e2579-3d81-800b-f0f1-00000000000f): 11.00
    Check if OpenSSH keypair does not match target configuration (299e2579-3d81-800b-f0f1-000000000011): 11.00
    Abort playbook if keypair was found and does not match target configuration (299e2579-3d81-800b-f0f1-000000000012): 14.00
    Create OpenSSH keypair for accessing managed nodes (299e2579-3d81-800b-f0f1-000000000014): 17.00
    Gathering Facts (299e2579-3d81-800b-f0f1-000000000060): 41.00
    Install SSH daemon (299e2579-3d81-800b-f0f1-000000000017): 43.00
    Start SSH daemon (299e2579-3d81-800b-f0f1-000000000018): 33.00
    Remove /run/nologin to be able to login as unprivileged user (299e2579-3d81-800b-f0f1-000000000019): 29.00
    Add public key of workshop SSH keypair to authorized_keys of ansible user (299e2579-3d81-800b-f0f1-00000000001a): 37.00
    ```

!!! tip
    Create an *alias* for the *cgexec...* part:

    !!! example "~/.bash_aliases"
        ```console
        alias ansible-playbook-profile='cgexec -g cpuacct,memory,pids:ansible_profile ansible-playbook'
        ```

    First time usage requires `source ~/.bash_aliases`, now you can run:

    ```console
    ansible-playbook-profile -i inventory playbook.yml
    ```

# Job Templates

A *job template* is a definition and set of parameters for running an Ansible job. Job templates are useful to run the same job many times.

## Variables

Along with any extra variables set in the job template and survey, automation controller automatically adds some [special variables to the job environment](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/latest/html/using_automation_execution/controller-job-templates#controller-job-template-variables){:target="_blank"}.  

For compatibility, all variables are  given an `awx` prefix, they are defined by the system and **cannot be overridden**.

* `awx_job_template_id`: The job template ID that this job run uses.
* `awx_project_revision`: The revision identifier for the source tree that this particular job uses (it is also the same as the job’s field scm_revision).
* `awx_user_id`: The user ID of the automation controller user that started this job. This is not available for callback or scheduled jobs.

!!! info

    These are just some examples, take a look at the [full list of Job environment variable](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-job-templates){:target="_blank".}  

## Surveys

Surveys provide a way to prompt users for input when launching a job from a job template.  
A survey can consist of any number of questions. For each question, choose an appropriate `type`:

| Type             | Description                                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------------- |
| `text`           | To provide a *textual* answer in a single line. You can set the minimum and maximum length (in characters). |
| `textarea`       | A multi-line text field. You can set the minimum and maximum length (in characters).                        |
| `password`       | To provide a password or other sensitive information.                                                       |
| `integer`        | To provide a whole number answer.                                                                           |
| `float`          | To Provide a decimal number.                                                                                |
| `multiplechoice` | To provide a list of options, only a single element can be chosen.                                          |
| `multiselect`    | To provide a list where multiple elements can be selected.                                                  |

### Mimic survey input during development

Survey variables are `extra-vars`, gather all survey variables in a file and provide the file in the `ansible-playbook` call:

```yaml title="survey_input.yml"
survey_input_overwrite_ssh_keys_boolean: true
survey_input_selinux_mode: enforcing
```

```console
ansible-playbook playbook.yml -e @survey_input.yml
```

Otherwise, you'll need to provide `-e` (or `--extra-vars`) multiple times for every input variable.

### Booleans

It is **not** possible to provide a `boolean` type in a survey, you'll need to *workaround* this by using the `multiplechoice` type and later use the `bool` filter in the playbook.

```yaml
name: Basic Survey
description: Survey Spec for question to provide a boolean value
spec:
  - question_name: Overwrite SSH authorized keys?
    question_description: Should all other non-specified keys from the authorized_keys file be removed?
    type: multiplechoice
    required: true
    choices: true\nfalse
    default: "false"
    variable: survey_input_overwrite_ssh_keys_boolean
```

In the task (or variable) itself, use the *survey* variable and add the `bool` filter.

```yaml
- name: Add public key for Ansible user
  ansible.posix.authorized_key:
    user: ansible
    key: "{{ lookup('file', 'ansible_key.pub') }}"
    exclusive: "{{ survey_input_overwrite_ssh_keys_boolean | bool }}"
    state: present
```

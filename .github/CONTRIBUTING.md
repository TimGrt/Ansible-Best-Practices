# Contributing Guidelines

Thank you for taking the time to contributing to the *Ansible Best Practice Guide*!

## Pull Request Guidelines

Before opening a *pull request* make sure you followed the next couple of steps.

1. Use the provided `Makefile` to create a development environment!
2. Always **preview** the changes you made thoroughly, only commit your changes if everything looks as intended!
3. Use the provided *pre-commit* configuration, it will lint your Markdown files and also check for spelling errors!

### Create development environment

Run the provided *Makefile*, the `all` target creates a Python VE with all requirements and installs the provided *pre-commit* hooks:

```console
make all
```

Running without specifying a target displays a *help* message.

### Delete development environment

When you are done with your work, run the *Makefile* with the `clean` target:

```console
make clean
```

## Documentation Guidelines

To ensure that the *Best Practice Guide* has a common *look and feel* take a look and follow the next guidelines when contributing to the documentation.
### Basic rules

The *Ansible Best Practice Guide* should follow a common *style*, it should be easy to read and strive to explain good practices without being too technical (although explaining the technical reasoning behind a proposed practice should be done if necessary).  
Use your best judgement, take a look at the basic rules of the [Ansible documentation style guide](https://docs.ansible.com/ansible/latest/dev_guide/style_guide/index.html#style-guide), they give a good starting point:

* [Basic rules](https://docs.ansible.com/ansible/latest/dev_guide/style_guide/basic_rules.html)
* [Grammar and punctuation](https://docs.ansible.com/ansible/latest/dev_guide/style_guide/grammar_punctuation.html)
* [Spelling](https://docs.ansible.com/ansible/latest/dev_guide/style_guide/spelling_word_choice.html)

The following topics should help you developing [*MkDocs*](https://www.mkdocs.org/) documentation with the [*Material*](https://squidfunk.github.io/mkdocs-material/) theme and show some documentation standards of this guide.

### Internal and external links

**Internal** anchors should link to the *sub-heading* in the contents of the page. You need to provide the name of the documentation file, suffix it with a hash sign and the sub-heading (whitespaces are replaced with dashes). If you are unsure about the spelling, preview the page you want to link to and take a look at the address line.

```markdown
... reference a module with the [FQCN](tasks.md#modules-and-collections)
```

If you create a new sub-section (the navigation on the left), always ensure that the `index.md` page of the section (e.g. `docs/ansible/index.md`) contains a link with an appropriate [16px logo](https://primer.style/design/foundations/icons), linking to the top of the sub-section page.

All **external** links must open in a new tab, use the `{ target=_blank }` attribute, for example:

```markdown
Download the collection tarball from [Galaxy](https://galaxy.ansible.com/){ target=_blank } for offline use.
```

While previewing your work, test that the links work as expected.

### Code blocks

Code blocks must be enclosed with two separate lines containing **three** *backticks*, followed by a *lexer* for syntax highlighting.
Use to correct [*lexer*](https://pygments.org/docs/lexers/) for highlighting the syntax of your code block, the most used ones are:

* `console` - for generic console output
* `yaml` - for all Ansible content or generic YAML files
* `python`
* `ini` - for Ansible inventory files or generic INI files

For example, a code block containing a playbook may look like this:

~~~markdown
```yaml
- name: Example playbook
  hosts: localhost
  tasks:
    - name: Example output
      ansible.builtin.debug:
        msg: "{{ ansible_default_ipv4.address }}
```
~~~

> As this Guide should show Good and Best Practices, always ensure that your Ansible example content follows the rules that this guide proposes!

If you want to add a *filename* to your example content, use the `title="<custom title>"` option. The [MkDocs Material documentation](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/#usage) shows even more possibilities (annotations, line numbers, highlighting specific lines, ...), use what is available! 

A special case are *Mermaid* diagrams, these are also enclosed by backticks in a code block (`mermaid`), but are rendered differently.
Take a look at the [MkDocs Material documentation](https://squidfunk.github.io/mkdocs-material/reference/diagrams/#usage) for usage instructions.

#### Copy or not to copy

By default, every code block has a small *copy* button in the top-right corner, if your code block e.g. contains only example output from the shell, it should not by copyable. Disable the copy button **per** code block with `.no-copy`, the syntax is slightly different:

~~~markdown
``` { .console .no-copy}
# Code block content
```
~~~

> Always pose yourself the question, can the code block content be pasted into the shell as is?  
> If not, it should not by copyable!

Additional information can be found in the [MkDocs Material documentation](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/#code-copy-button).
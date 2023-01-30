<div>

    {% if config.site_name %}
        <h1>{{ config.site_name }}</h1>
    {% endif %}

</div>

<p>
    <img src="../assets/images/computacenter.png" width=500/>
</p>

{% if config.site_description %}
<p>
    {{ config.site_description }}
</p>
{% endif %}

{% if config.copyright %}
<p>
    <em>{{ config.copyright }}</em>
</p>
{% endif %}

{% macro get_gcp_projects() %}
    {% set database_query %}
        select distinct * from (
            {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "model") | list
                + graph.nodes.values() | selectattr("resource_type", "equalto", "seed") | list
                + graph.nodes.values() | selectattr("resource_type", "equalto", "snapshot") | list %}
            select "{{ node.database }}" as database_name
                {%- if not loop.last %}
                union all
                {% endif -%}
            {% endfor %}
        ) as database_names
    {% endset %}
    {% do log(database_query, True) %}
    {% if execute %}
        {% set gcp_projects = run_query(database_query).columns[0].values() %}
        {{ gcp_projects }}
        {% do return(gcp_projects) %}
    {% endif %}
{%- endmacro -%}

{%- macro drop_pr_schemas_per_gcp_project(gcp_project_id, job_id, pr_number, dry_run, region='region-eu') %}
    {% set pr_cleanup_query %}
        with pr_staging_schemas as (
            select schema_name
            from `{{ gcp_project_id }}.{{ region }}.INFORMATION_SCHEMA.SCHEMATA`
            where starts_with(schema_name, 'dbt_cloud_pr_' || {{ job_id }} || '_' )
            and cast(split(schema_name, '_')[offset(4)] AS int) <= cast({{ pr_number }} as int)
        )
        select
            'drop schema if exists `{{ gcp_project_id }}.' || schema_name || '` cascade;' as drop_command
        from pr_staging_schemas
    {% endset %}

    {{ pr_cleanup_query }}
    {% do log(pr_cleanup_query, info=True) %}

    {% if execute %}

        {% set drop_commands = run_query(pr_cleanup_query).columns[0].values() %}

        {% if drop_commands %}
            {% for drop_command in drop_commands %}
                {% do log(drop_command, True) %}
                {% if not dry_run %} {% do run_query(drop_command) %} {% endif %}
            {% endfor %}
        {% else %} {% do log('No schemas to drop.', True) %}
        {% endif %}

    {% endif %}

{%- endmacro -%}

{% macro drop_pr_schemas(job_id, pr_number, dry_run=True) %}
    {% if execute %}
        {% for gcp_project in get_gcp_projects() %}
            {% do drop_pr_schemas_per_gcp_project(gcp_project, job_id, pr_number, dry_run) %}
        {% endfor %}

    {% endif %}

{%- endmacro -%}

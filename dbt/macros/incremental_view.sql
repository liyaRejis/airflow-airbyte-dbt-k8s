{% macro view__incremental_clause(col_emitted_at, table_list, view) %}
    {% if is_incremental() %}
        AND (
            {% for table in table_list %}
                {{table}}.{{col_emitted_at}} >= (SELECT MAX({{ col_emitted_at }}) FROM {{view}})      
                {% if not loop.last %}
                    OR
                {% endif %}
            {% endfor %}
        )
    {% endif %}
{% endmacro %}

{% macro incremental_filter(updated_col="_ab_cdc_updated_at", deleted_col="_ab_cdc_deleted_at") %}
    {% if is_incremental() %}
        AND (
            {{ updated_col }}::timestamp > (
                SELECT MAX({{ updated_col }}::timestamp) FROM {{ this }}
            )
            OR {{ deleted_col }}::timestamp > COALESCE(
                (SELECT MAX({{ deleted_col }}::timestamp) FROM {{ this }}),
                'epoch'::timestamp
            )
        )
    {% endif %}
{% endmacro %}

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

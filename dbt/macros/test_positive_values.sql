/*
  Generic test — asserts that all non-null values in a column are positive (> 0).

  Usage in schema YAML:
    columns:
      - name: weight_min_lb
        tests:
          - positive_values
*/

{% test positive_values(model, column_name) %}

select
    {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and {{ column_name }} <= 0

{% endtest %}

/*
  Singular test — validates that life_span_min never exceeds life_span_max.

  Any rows returned indicate a parsing or data-quality issue.
*/

select
    breed_id,
    life_span_min_years,
    life_span_max_years
from {{ ref('fact_weight_life_span') }}
where life_span_min_years > life_span_max_years

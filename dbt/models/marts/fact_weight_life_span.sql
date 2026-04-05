{{
  config(
    materialized = 'table',
    description  = 'Fact table with numeric weight, height, and life-span measurements per breed.'
  )
}}

/*
  fact_weight_life_span — all numeric measurements for each breed, plus
  computed averages for quick analytical access.
*/

with staged as (

    select * from {{ ref('stg_dog_breeds') }}
    where life_span_min_years is not null

),

metrics as (

    select
        id                                                       as breed_id,

        -- ── life span ────────────────────────────────────────────────────
        life_span_min_years,
        life_span_max_years,
        round((life_span_min_years + life_span_max_years) / 2.0, 1) as life_span_avg_years,

        -- ── weight (imperial / metric) ───────────────────────────────────
        weight_min_lb,
        weight_max_lb,
        round((weight_min_lb + weight_max_lb) / 2.0, 1)         as weight_avg_lb,
        weight_min_kg,
        weight_max_kg,
        round((weight_min_kg + weight_max_kg) / 2.0, 1)         as weight_avg_kg,

        -- ── height (imperial / metric) ───────────────────────────────────
        height_min_in,
        height_max_in,
        round((height_min_in + height_max_in) / 2.0, 1)         as height_avg_in,
        height_min_cm,
        height_max_cm,
        round((height_min_cm + height_max_cm) / 2.0, 1)         as height_avg_cm

    from staged

)

select * from metrics

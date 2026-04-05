{{
  config(
    materialized = 'view',
    description  = 'Cleaned and type-cast dog breed data with parsed numeric fields for life span, weight, and height.'
  )
}}

/*
  Staging model — normalises the raw JSON that dlt loaded into bronze.dog_api_raw.

  Key transformations
  ───────────────────
  • Parse "10 - 12 years"  →  life_span_min_years (INT), life_span_max_years (INT)
  • Parse "50 - 60"        →  weight_min_lb / weight_max_lb  (FLOAT64)
  • Parse metric variants  →  weight_min_kg / weight_max_kg  (FLOAT64)
  • Parse height strings   →  height_min_in / height_max_in, height_min_cm / height_max_cm
  • Handle single-value strings (e.g. "50" without a range) via COALESCE.
*/

with source as (

    select * from {{ source('bronze', 'dog_api_raw') }}

),

parsed as (

    select
        -- ── identifiers ──────────────────────────────────────────────────
        cast(id as int64)                                        as id,
        name,
        trim(breed_group)                                        as breed_group,
        trim(bred_for)                                           as bred_for,
        trim(origin)                                             as origin,
        trim(temperament)                                        as temperament,
        reference_image_id,

        -- ── life span (e.g. "10 - 12 years") ────────────────────────────
        safe_cast(regexp_extract(life_span, r'^(\d+)')    as int64) as life_span_min_years,
        coalesce(
            safe_cast(regexp_extract(life_span, r'-\s*(\d+)') as int64),
            safe_cast(regexp_extract(life_span, r'^(\d+)')     as int64)
        )                                                        as life_span_max_years,

        -- ── weight imperial (lbs, e.g. "50 - 60") ───────────────────────
        safe_cast(regexp_extract(weight__imperial, r'^([\d.]+)')      as float64) as weight_min_lb,
        coalesce(
            safe_cast(regexp_extract(weight__imperial, r'-\s*([\d.]+)') as float64),
            safe_cast(regexp_extract(weight__imperial, r'^([\d.]+)')    as float64)
        )                                                        as weight_max_lb,

        -- ── weight metric (kg, e.g. "23 - 27") ──────────────────────────
        safe_cast(regexp_extract(weight__metric, r'^([\d.]+)')        as float64) as weight_min_kg,
        coalesce(
            safe_cast(regexp_extract(weight__metric, r'-\s*([\d.]+)')   as float64),
            safe_cast(regexp_extract(weight__metric, r'^([\d.]+)')      as float64)
        )                                                        as weight_max_kg,

        -- ── height imperial (inches, e.g. "25 - 27") ────────────────────
        safe_cast(regexp_extract(height__imperial, r'^([\d.]+)')      as float64) as height_min_in,
        coalesce(
            safe_cast(regexp_extract(height__imperial, r'-\s*([\d.]+)') as float64),
            safe_cast(regexp_extract(height__imperial, r'^([\d.]+)')    as float64)
        )                                                        as height_max_in,

        -- ── height metric (cm, e.g. "64 - 69") ──────────────────────────
        safe_cast(regexp_extract(height__metric, r'^([\d.]+)')        as float64) as height_min_cm,
        coalesce(
            safe_cast(regexp_extract(height__metric, r'-\s*([\d.]+)')   as float64),
            safe_cast(regexp_extract(height__metric, r'^([\d.]+)')      as float64)
        )                                                        as height_max_cm

    from source

)

select * from parsed

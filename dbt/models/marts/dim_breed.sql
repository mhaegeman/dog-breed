{{
  config(
    materialized = 'table',
    description  = 'Breed dimension with enriched attributes: weight class and family-friendly flag.'
  )
}}

/*
  dim_breed — one row per breed, enriched with derived classifications.

  • weight_class     : Toy / Small / Medium / Large / Giant based on average imperial weight.
  • is_family_friendly: TRUE when temperament contains family-oriented keywords.
*/

with staged as (

    select * from {{ ref('stg_dog_breeds') }}

),

enriched as (

    select
        id                                                       as breed_id,
        name                                                     as breed_name,
        breed_group,
        temperament,
        reference_image_id,

        -- ── weight class based on average imperial weight ────────────────
        case
            when weight_min_lb is null or weight_max_lb is null then 'Unknown'
            when (weight_min_lb + weight_max_lb) / 2.0 < 10     then 'Toy'
            when (weight_min_lb + weight_max_lb) / 2.0 < 25     then 'Small'
            when (weight_min_lb + weight_max_lb) / 2.0 < 50     then 'Medium'
            when (weight_min_lb + weight_max_lb) / 2.0 < 100    then 'Large'
            else                                                      'Giant'
        end                                                      as weight_class,

        -- ── family-friendly flag ─────────────────────────────────────────
        coalesce(
            regexp_contains(
                lower(temperament),
                r'friendly|gentle|good-natured|playful|loyal|affectionate'
            ),
            false
        )                                                        as is_family_friendly

    from staged

)

select * from enriched

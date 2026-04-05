-- ──────────────────────────────────────────────────────────────────────────────
-- Looker Studio View 3: Top temperaments among family-friendly breeds
-- ──────────────────────────────────────────────────────────────────────────────
-- Splits the comma-separated temperament string into individual traits and
-- ranks them by frequency across family-friendly breeds.
-- Replace `your-project` with your actual GCP project ID.

with family_breeds as (

    select
        d.breed_id,
        d.breed_name,
        d.temperament,
        d.weight_class,
        f.life_span_avg_years
    from
        `your-project.analytics.dim_breed` as d
    inner join
        `your-project.analytics.fact_weight_life_span` as f
        using (breed_id)
    where
        d.is_family_friendly = true

),

-- Unnest each comma-separated temperament trait into its own row
traits as (

    select
        breed_id,
        breed_name,
        weight_class,
        life_span_avg_years,
        trim(trait) as temperament_trait
    from
        family_breeds,
        unnest(split(temperament, ',')) as trait

)

select
    temperament_trait,
    count(distinct breed_id)                       as breed_count,
    round(avg(life_span_avg_years), 1)             as avg_life_span_years,
    array_to_string(
        array_agg(distinct weight_class order by weight_class), ', '
    )                                              as weight_classes_represented
from
    traits
group by
    temperament_trait
order by
    breed_count desc
limit 25

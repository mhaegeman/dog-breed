-- ──────────────────────────────────────────────────────────────────────────────
-- Looker Studio View 1: Breeds with the longest predicted life span
-- ──────────────────────────────────────────────────────────────────────────────
-- Use this query as a custom SQL data source in Looker Studio.
-- Replace `your-project` with your actual GCP project ID.

select
    d.breed_name,
    d.breed_group,
    d.weight_class,
    f.life_span_min_years,
    f.life_span_max_years,
    f.life_span_avg_years,
    f.weight_avg_lb
from
    `your-project.analytics.fact_weight_life_span` as f
inner join
    `your-project.analytics.dim_breed` as d
    using (breed_id)
order by
    f.life_span_avg_years desc
limit 20

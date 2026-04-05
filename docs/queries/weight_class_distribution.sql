-- ──────────────────────────────────────────────────────────────────────────────
-- Looker Studio View 2: Distribution of breeds by weight class
-- ──────────────────────────────────────────────────────────────────────────────
-- Powers a bar/pie chart showing how many breeds fall into each size bucket.
-- Replace `your-project` with your actual GCP project ID.

select
    d.weight_class,
    count(*)                                       as breed_count,
    round(count(*) * 100.0 / sum(count(*)) over(), 1) as pct_of_total,
    round(avg(f.weight_avg_lb), 1)                 as avg_weight_lb,
    round(avg(f.life_span_avg_years), 1)           as avg_life_span_years
from
    `your-project.analytics.dim_breed` as d
inner join
    `your-project.analytics.fact_weight_life_span` as f
    using (breed_id)
where
    d.weight_class != 'Unknown'
group by
    d.weight_class
order by
    avg_weight_lb

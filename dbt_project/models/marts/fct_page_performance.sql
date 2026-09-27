{{ config(cluster_by=["report_date", "page_path"]) }}

with

page_views as (
    select * from {{ ref('int_ga4__page_views') }}
),

aggregated as (
    select
        first_seen_date as report_date,
        page_path,
        sum(page_view_count) as page_views,
        countif(page_view_count > 0) as sessions,
        count(distinct user_pseudo_id ) as users,
        sum(engagement_time_secs) as engagement_time_secs
    from page_views
    group by first_seen_date, page_path
),

final as (
    select
        *,
        safe_divide(engagement_time_secs, sessions) as avg_engagement_secs_per_session
    from aggregated
)

select * from final
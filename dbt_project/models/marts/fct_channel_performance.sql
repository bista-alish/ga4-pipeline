{{ config(cluster_by = ["report_date", "channel_group", "first_user_source"]) }}

with

sessions as (
    select * from {{ ref('int_ga4__sessions') }}
),

classified as (
    select 
        *,
        {{ channel_grouping('first_user_source', 'first_user_medium') }} as channel_group
    from sessions  
),

aggregated as (
    select
        session_date as report_date,
        channel_group,
        first_user_source,
        first_user_medium,
        count(*) as sessions,
        count(distinct user_pseudo_id) as users,
        countif(has_conversion) as converting_sessions,
        sum(page_view_count) as page_views,
        sum(conversion_count) as conversions,
        sum(revenue_usd) as revenue_usd
    from classified
    group by session_date, channel_group, first_user_source, first_user_medium
),

final as (
    select
        *,
        safe_divide(converting_sessions, sessions) as conversion_rate,
        safe_divide(revenue_usd, sessions) as revenue_per_session_usd
    from aggregated

)

select * from final
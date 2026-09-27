{{ config(cluster_by = ["report_date", "channel_group"]) }}

with

sessions as (
    select *  from {{ ref('int_ga4__sessions') }}
),

classified as (
    select
        *,
        {{ channel_grouping('first_user_source', 'first_user_medium') }}as channel_group
    from sessions
),

daily as (
    select
        session_date as report_date,
        channel_group,
        count(*) as sessions,
        count(distinct user_pseudo_id) as users,
        countif(is_engaged_session) as engaged_sessions,
        countif(has_conversion) as converting_sessions,
        sum(page_view_count) as page_views,
        sum(conversion_count) as conversions,
        sum(revenue_usd) as revenue_usd,
        sum(engagement_time_secs) as engagement_time_secs
    from classified
    group by session_date, channel_group
),

final as (
    select
        *,
        safe_divide(engaged_sessions, sessions) as engagement_rate,
        1 - safe_divide(engaged_sessions, sessions) as bounce_rate,
        safe_divide(converting_sessions, sessions) as conversion_rate,
        safe_divide(engagement_time_secs, sessions) as avg_engagement_secs_per_session
    from daily
)

select * from final
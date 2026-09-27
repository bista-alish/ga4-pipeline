{{ config(
    cluster_by=["session_date", "first_user_medium", "first_user_source"]
) }}

with 

events as (
    select * 
    from {{ ref('stg_ga4__events') }}
    where ga_session_id is not null
),

sessions as (
    select
        concat(user_pseudo_id, '-', cast(ga_session_id as string)) as session_key,
        user_pseudo_id,
        ga_session_id,
        min(event_date) as session_date,
        min(event_timestamp_utc) as session_start_at,
        max(event_timestamp_utc) as session_end_at,
        max(device_category) as device_category,
        max(country) as country,
        max(first_user_source) as first_user_source,
        max(first_user_medium) as first_user_medium,
        array_agg(page_location ignore nulls order by event_timestamp_utc limit 1)[safe_offset(0)] as landing_page,
        count(*) as event_count,
        countif(event_name = 'page_view') as page_view_count,
        countif(event_name in ('{{ var("conversion_events") | join("', '") }}')) as conversion_count,
        coalesce(sum(purchase_revenue_usd), 0) as revenue_usd,
        coalesce(sum(engagement_time_msec), 0) / 1000 as engagement_time_secs
    from events
    group by user_pseudo_id, ga_session_id
),

final as (
    select
        *,
        conversion_count > 0 as has_conversion,
        (engagement_time_secs >=10 or page_view_count >= 2 or conversion_count > 0) as is_engaged_session 
    from sessions
)

select * from final
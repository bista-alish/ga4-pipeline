
with source as (
    select
        event_date,
        event_timestamp,
        event_name,
        user_pseudo_id,
        event_params,
        geo,
        device,
        traffic_source,
        ecommerce
    from {{ source('ga4_public', 'events')  }}
    where _table_suffix = '20201201'
),
deduplicated as (
    select *
    from source
    where true
    qualify row_number() over (
        partition by user_pseudo_id, event_timestamp, event_name, to_json_string(event_params)
        order by event_timestamp
    ) = 1
),
flattened as (
    select
        parse_Date('%Y%m%d', event_date) as event_date,
        timestamp_micros(event_timestamp) as event_timestamp_utc,
        event_name,
        user_pseudo_id,
        (select value.int_value from UNNEST(event_params) WHERE key = 'ga_session_id') as ga_session_id,
        (select value.string_value from UNNEST(event_params) WHERE key = 'page_location') as page_location,
        (select value.int_value from UNNEST(event_params) WHERE key = 'engagement_time_msec') as engagement_time_msec,
        device.category as device_category,
        geo.country as country,
        traffic_source.source as first_user_source,
        traffic_source.medium as first_user_medium,
        ecommerce.purchase_revenue_in_usd as purchase_revenue_usd
    from deduplicated
),
cleaned as (
    select 
        event_date,
        event_timestamp_utc,
        event_name,
        user_pseudo_id,
        ga_session_id,
        page_location,
        engagement_time_msec,
        case when device_category in ('(not set)', '<Other>', '(data deleted)') then null else device_category end as device_category,
        case when country in ('(not set)' ,'<Other>', '(data deleted)') then null else country end as country,
        case when first_user_source in ('(not set)', '<Other>', '(data deleted)') then null else first_user_source end as first_user_source,
        case when first_user_medium in ('(not set)', '<Other>', '(data deleted)') then null else first_user_medium end as first_user_medium,
        purchase_revenue_usd
    from flattened
)

select * from cleaned
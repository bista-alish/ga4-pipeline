with

events as (
    select
        concat(user_pseudo_id, '-', cast(ga_session_id as string)) as session_key,
        user_pseudo_id,
        event_date,
        event_timestamp_utc,
        event_name,
        case
            when regexp_contains(page_location, r'^https?://')
                then coalesce(regexp_extract(page_location, r'^https://[^/]+(/[^?#]*)'), '/')
        end as page_path,
        engagement_time_msec
    from {{ ref('stg_ga4__events') }}
    where ga_session_id is not null
),

page_views as (
        select
            session_key,
            user_pseudo_id,
            page_path,
            min(event_date) as first_seen_date,
            min(event_timestamp_utc) as first_seen_at,
            countif(event_name = 'page_view') as page_view_count,
            coalesce(sum(engagement_time_msec), 0) / 1000 as engagement_time_secs
        from events
        where page_path is not null
        group by session_key, user_pseudo_id, page_path
)

select * from page_views
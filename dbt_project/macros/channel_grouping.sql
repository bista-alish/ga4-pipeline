{% macro channel_grouping(source_col, medium_col) %}
    case
        when {{ source_col }} = '(direct)' and {{ medium_col }} = '(none)' then 'Direct'
        when {{ medium_col }} = 'organic' then 'Organic Search'
        when {{ medium_col }} in ('cpc', 'ppc', 'paidsearch') then 'Paid Search'
        when {{ medium_col }} in ('social', 'social-network', 'sm')
            or {{ source_col }} in ('facebook', 'instagram', 'twitter', 'linkedin', 'tiktok') then 'Social'
        when {{ medium_col }} in ('email', 'e-mail') then 'Email'
        when {{ medium_col }} = 'referral' then 'Referral'
        when {{ medium_col }} in ('display', 'banner', 'cpm') then 'Display'
        when {{ source_col }} is null and {{ medium_col }} is null then 'Unknown'
        else 'Other'
    end
{% endmacro %}
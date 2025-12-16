-- 1. Redemption rate: % completion out of % sent.

with 
offer_stat as ( 
	select 
		offer_id 
		, event 
		, count(*) as impressions
	from
		customers_events ce
	left join 
		customers_members cm 
		on ce.customer_id = cm.customer_id
	where 
		income_cat is null -- excluding customers with no gender, age and income (12.8% of the dataset, which can be significant; however, this step was critical for clarifying customer behavior patterns).
	group by 
		1, 2 
)
, all_events as (
	select 
		distinct event 
	from 
		customers_events
	where 
		event != 'transaction'
)
, all_offers as (
	select 
		distinct offer_id 
	from 
		customers_events
)
, all_combinaisons as (
	select 
		all_offers.offer_id 
		, all_events.event 
	from 
		all_offers 
	cross join 
		all_events
)
, offer_stat_all as (
	select 
		all_combinaisons.offer_id 
		, all_combinaisons.event 
		, coalesce(offer_stat.impressions, 0) as impressions
	from 
		all_combinaisons 
	left join 
		offer_stat 
		on all_combinaisons.offer_id = offer_stat.offer_id 
		and all_combinaisons.event = offer_stat.event
	where 
		all_combinaisons.offer_id is not null
) 
, conversion_rates as ( 
	select 
		* 
		, case when event = '1. offer_received' then impressions else 0 end as received_impressions
		, coalesce(lag(impressions, 1) over(partition by offer_id order by event), 0) as lag_impressions
		, coalesce(
				round(100.0*impressions / nullif(coalesce(lag(impressions, 1) over(partition by offer_id order by event), 0), 0), 1)
		  , 0) as step_to_step_cr
		, round(100.0*impressions / nullif(max(impressions) over(partition by offer_id), 0), 1) as end_to_end_cr
	from 
		offer_stat_all
)  

select 
	distinct conversion_rates.offer_id 
	, offer_type
	, difficulty 
	, reward 
	, duration 
	, channels 
	, t0.received_impressions as nb_received
	, t1.impressions as nb_viewed
	, t2.impressions as nb_completed
	, t1.step_to_step_cr as pct_viewed
	, t2.end_to_end_cr as pct_completed
from 
	conversion_rates 
left join 
	offers
	on conversion_rates.offer_id = offers.offer_id 
left join 
	conversion_rates t0 
	on conversion_rates.offer_id = t0.offer_id 
	and t0.event = '1. offer_received'
left join 
	conversion_rates t1 
	on conversion_rates.offer_id = t1.offer_id 
	and t1.event = '2. offer_viewed'
left join 
	conversion_rates t2
	on conversion_rates.offer_id = t2.offer_id 
	and t2.event = '3. offer_completed' 
order by 
	pct_completed desc

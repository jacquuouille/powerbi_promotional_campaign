-- COHORT ANALYSIS 
-- track customers repeat purchase behaviour over the next days, split into 2 groups:
   -- 1. those who completed at least 1 offer 
   -- 2. those who did not complet any


-- 
-- 1. Completed segments (= customers who completed at least 1 offer)  
--

with 
completed_users_tbl as (
	select 
		distinct customer_id  
	from 
		customers_events 
	left join 
		customers_members cm 
		on ce.customer_id = cm.customer_id
	where 
		income_cat is null -- excluding customers with no gender, age and income referred (12.8% of the dataset, which can be significant; however, this step was critical for clarifying customer behavior patterns).
		and event = '3. offer_completed' 
)
, transactions_tbl as ( 
	select 
		distinct ce.*
		, row_number() over(partition by ce.customer_id order by time) as nb_transaction
	from 
		customers_events ce
	join 
		completed_users_tbl cut
		on ce.customer_id = cut.customer_id 
	where 
		ce.event = 'transaction' -- looking at all customers' transactions 
)
, cohort_buckets_tbl as ( 
	select 	
		distinct customer_id 
		, day as cohort_day 
	from 
		transactions_tbl 
	where 
		nb_transaction = 1 -- cohort corresponds to the day customers make their first purchase within the 30-day window.
	group by 	
		1, 2
)
, user_activities_tbl as ( 
	select 
		tt.*
		, (tt.day - cbt.cohort_day) as day_retained
	from 
		transactions_tbl tt
	join 
		cohort_buckets_tbl cbt
		on tt.customer_id = cbt.customer_id 
	where 
		nb_transaction > 1 -- returning day refers to the next purchase day on which customers make another purchase after the initial (cohort) purchase.
)
, cohort_size_tbl as (
	select 
		cohort_day
		, count(distinct customer_id) as nb_users 
	from 
		cohort_buckets_tbl
	group by 
		1
)
, retention_tbl as (
	select 
		cbt.cohort_day
		, uat.day_retained 
		, count(distinct uat.customer_id) as nb_users 
	from 
		user_activities_tbl uat 
	left join 
		cohort_buckets_tbl cbt 
		on uat.customer_id = cbt.customer_id
	group by 
		1, 2
)

select
	rt.cohort_day 
	, rt.day_retained 
	, cst.nb_users as total_users
	, rt.nb_users as retained_users
	, round(100.0*rt.nb_users / cst.nb_users, 1) as pct_retention 
from 
	retention_tbl rt 
left join 
	cohort_size_tbl cst
	on rt.cohort_day = cst.cohort_day
order by 
	1, 3


-- 
-- 2. Not-completed segments (= customers who did not complet any) 
-- 

-- same code, by looking at the following cohorts: 

completed_users_tbl as (
	select 
		distinct customer_id  
	from 
		customers_events 
	left join 
		customers_members cm 
		on ce.customer_id = cm.customer_id
	where 
		income_cat is null
		and event = '3. offer_completed' 
)
, non_completed_users_tbl as (
	select 
		distinct ce.customer_id 
	from 
		customers_events ce 
	left join 
		completed_users_tbl cut 
		on ce.customer_id = cut.customer_id 
	where 
		cut.customer_id is null
)
... 

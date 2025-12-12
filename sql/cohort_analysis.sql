-- COHORT ANALYSIS 
-- track customers repeat behaviour (= transaction) over the next months

-- 1. USERS WHO HAVE COMPLETED AT LEAST 1 OFFER

with 
completed_users_tbl as (
	select 
		distinct customer_id  
	from 
		customers_events 
	join 
		customers_members cm 
		on ce.customer_id = cm.customer_id
	where 
		income_cat is not null 
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
		ce.event = 'transaction' 
)
, cohort_buckets_tbl as ( 
	select 	
		distinct customer_id 
		, day as cohort_day 
	from 
		transactions_tbl 
	where 
		nb_transaction = 1
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
		nb_transaction > 1
		-- and tt.customer_id = '004c5799adbf42868b9cff0396190900' order by 1, time
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

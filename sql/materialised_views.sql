--
-- 1. Customer Members View
--

CREATE MATERIALIZED VIEW customers_members 
AS
  
select 
	customer_id 
	, to_date(became_member_on::text, 'YYYYMMDD') as date 
	, gender 
	, case 
  		when age between 18 and 24 then '18-24' -- young adults
  		when age between 25 and 34 then '25-34' -- early career adults
  		when age between 35 and 44 then '35-44' -- middle-aged millennials
  		when age between 45 and 54 then '45-54' -- mature adults
  		when age between 55 and 64 then '55-64' -- pre-retirees
  		when age >= 65 then '65+' -- retirees 
		  else null 
		end as age_cat
	, case
  		when income between 30000 and 49999 then '1. 30K-49K' -- lower income
  		when income between 50000 and 69999 then '2. 50K-69K' -- middle income
  		when income between 70000 and 89999 then '3. 70K-100K' -- upper/midle income
  		when income >= 90000 then '4. 100K+' -- higher income 
  		else null 
		end as income_cat
	, case 
  		when (extract(year from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(), to_date(became_member_on::text, 'YYYYMMDD')))*12) + extract(month from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(), to_date(became_member_on::text, 'YYYYMMDD'))) <= 6 then '1. 0-6 months (New Accounts)'
  		when (extract(year from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(), to_date(became_member_on::text, 'YYYYMMDD')))*12) + extract(month from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(), to_date(became_member_on::text, 'YYYYMMDD'))) between 7 and 18 then '2. 7-18 months (Active Accounts)'
  		when (extract(year from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(), to_date(became_member_on::text, 'YYYYMMDD')))*12) + extract(month from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(), to_date(became_member_on::text, 'YYYYMMDD'))) between 19 and 36 then '3. 19-36 months (Established Accounts)'
  		when (extract(year from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(),to_date(became_member_on::text, 'YYYYMMDD')))*12) + extract(month from age(max(to_date(became_member_on::text, 'YYYYMMDD')) over(), to_date(became_member_on::text, 'YYYYMMDD'))) >= 37 then '4. 37+ months (Long-Term Accounts)'
		else null 
	end as tenure_cat
from 
	customers 
  
WITH NO DATA;


--
-- 2. Offers View
--

CREATE MATERIALIZED VIEW customers_members 
AS
  
select 
  *
from 
	offers 
  
WITH NO DATA;


--
-- 3. Customers Events View
-- 

CREATE MATERIALIZED VIEW customers_events 
AS
  
	select 
		distinct customer_id 
  
    -- 'event' -> to be ordered to properly calculate conversion rates (e.g., some customers complete the offer without viewing it. why?) 
		, case 
  			when event = 'offer received' then '1. offer_received'
  			when event = 'offer viewed' then '2. offer_viewed'
  			when event = 'offer completed' then '3. offer_completed'
  			else event 
			end as event
  
   -- 'value' -> to unnest in order to have 'offer_id', 'reward' and 'amount' as columns. Extracting the data this way removed duplicates (for offer completions, 396 records were duplicated (≈0.1%)).
	 	, case 
  			when value like '%offer id%' then regexp_replace(value, '.*offer id'':[[:space:]]*''([^'']+)''.*', '\1') 
  			when value like '%offer_id%' then regexp_replace(value, '.*offer_id'':[[:space:]]*''([^'']+)''.*', '\1')
  			else null 
			end as offer_id
		, case when value like '%reward%' then regexp_replace(value, '.*reward'':[[:space:]]*([0-9]+).*', '\1')::int else 0 end AS reward
		, case when value like '%amount%' then regexp_replace(value, '.*amount'':[[:space:]]*(-?[0-9]+(?:\.[0-9]+)?).*', '\1')::float else 0 end AS amount
  
		, time 
		, trunc(time / 24) as day
	from
		events  
  
WITH NO DATA;

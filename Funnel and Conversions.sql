Select * from user_events
LIMIT 10;

-- Sales Domain
-- define sales funnel and the different stages of funnel

WITH funnel_Stages AS (
	Select 
		COUNT(DISTINCT   CASE WHEN event_type ='page_view' THEN user_id END) AS stage_1_views,
		COUNT(DISTINCT 	CASE WHEN event_type='add_to_cart' THEN user_id END) AS stage_2_cart,
		COUNT(DISTINCT 	CASE WHEN event_type='checkout_start' THEN user_id END) AS stage_3_checkout,
		COUNT(DISTINCT 	CASE WHEN event_type='payment_info' THEN user_id END) AS stage_4_payment_info,
		COUNT(DISTINCT 	CASE WHEN event_type='purchase' THEN user_id END) AS stage_5_purchase_completed
	from user_events
where event_date >=TIMESTAMP(DATE_SUB('2026-02-10', INTERVAL 30 DAY)) 
)
Select * from funnel_Stages;

-- Analytics findings we are losing users as we are going down the funnel

-- COnversion rates
                WITH funnel_Stages AS (
	Select 
		COUNT(DISTINCT   CASE WHEN event_type ='page_view' THEN user_id END) AS stage_1_views,
		COUNT(DISTINCT 	CASE WHEN event_type='add_to_cart' THEN user_id END) AS stage_2_cart,
		COUNT(DISTINCT 	CASE WHEN event_type='checkout_start' THEN user_id END) AS stage_3_checkout,
		COUNT(DISTINCT 	CASE WHEN event_type='payment_info' THEN user_id END) AS stage_4_payment_info,
		COUNT(DISTINCT 	CASE WHEN event_type='purchase' THEN user_id END) AS stage_5_purchase_completed
	from user_events
where event_date >=TIMESTAMP(DATE_SUB('2026-02-10', INTERVAL 30 DAY)) 
)
Select 
	stage_1_views,
    stage_2_cart,
  ROUND(  stage_2_cart*100/stage_1_views)+'%' AS view_to_cart_rate,
    stage_3_checkout,
   ROUND( stage_3_checkout*100/stage_2_cart) AS cart_to_checkout_rate,
    stage_4_payment_info,
  ROUND(  stage_4_payment_info*100/stage_3_checkout) AS checkout_to_payment,
	stage_5_purchase_completed,
  ROUND( stage_5_purchase_completed*100/stage_4_payment_info) AS payment_to_purchase,
  ROUND( stage_5_purchase_completed*100/stage_1_views) AS views_to_purchase_rate
from funnel_Stages;

-- Lowest conversion from views to cart (improve UI or experience or unable to find things people are looking for?), payment to puchase is high (good)

-- funnel by source

WITH source_funnel AS(
Select 
traffic_source,
		COUNT(DISTINCT   CASE WHEN event_type ='page_view' THEN user_id END) AS views,
		COUNT(DISTINCT 	CASE WHEN event_type='add_to_cart' THEN user_id END) AS cart,
		COUNT(DISTINCT 	CASE WHEN event_type='purchase' THEN user_id END) AS purchases
	from user_events
where event_date >=TIMESTAMP(DATE_SUB('2026-02-10', INTERVAL 30 DAY)) 
group by traffic_source

)
Select traffic_source,
views,
cart,
purchases,
ROUND( cart*100/views) AS views_to_cart_conversion,
ROUND( purchases*100/cart) AS cart_to_purchases_conversion,
ROUND( purchases*100/views) AS views_to_purchase_conversion

 from source_funnel
 order by purchases desc;
 
 -- Analytics Email is doing best in converting view to purchase while social media is lowest performing marketing
 
 
 -- time to conversion analysis
 
 WITH user_journey AS(
Select 
user_id,
		MIN(   CASE WHEN event_type ='page_view' THEN event_date END) AS views_time,
		MIN( 	CASE WHEN event_type='add_to_cart' THEN event_date END) AS cart_time,
		MIN( 	CASE WHEN event_type='purchase' THEN event_date END) AS purchase_time
	from user_events
where event_date >=TIMESTAMP(DATE_SUB('2026-02-10', INTERVAL 30 DAY)) 
group by user_id
having 	MIN( 	CASE WHEN event_type='purchase' THEN event_date END) IS NOT NULL

)
Select 
	COUNT(*) AS converted_user,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, views_time, cart_time)),2) AS avg_view_to_Cart_minutes,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, cart_time, purchase_time)),2) AS avg_Cart_to_Purchase_minutes,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, views_time, purchase_time)),2) AS avg__total_journey_minutes
from user_journey;
-- avg time spent on website 24.5, more time spent cart to purchase (nothing alarming)



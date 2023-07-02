/*
Solutions to Case Study #1: Danny's Dinner
*/

-- 1. What is the total amount each customer spent at the restaurant?

select 
	s.customer_id,
	sum(m.price) as total_spent
from 
	dannys_dinner.sales s left join dannys_dinner.menu m
	on s.product_id = m.product_id
group by 
	customer_id
order by
	customer_id;

-- 2. How many days has each customer visited the restaurant?

select
	customer_id,
	count(distinct order_date) as n_days_visited
from 
	dannys_dinner.sales 
group by 
	customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte_ranked_orders as ( -- ranks every order (grouped per customer) according to the date 
	select 
		customer_id,
		order_date,
		product_id,
		rank() over (partition by customer_id order by order_date)
	from 
		dannys_dinner.sales 
)
select distinct -- we select distinct pairs of (customer_id, product_name) as it could be possible to order twice the same product on the first order
	cte.customer_id,
	m.product_name
from 
	cte_ranked_orders cte left join dannys_dinner.menu m
	on cte.product_id = m.product_id
where 
	rank = 1
order by 
	cte.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select
	m.product_name,
	count(m.product_id) as times_purchased
from 
	dannys_dinner.sales s left join dannys_dinner.menu m
	on m.product_id = s.product_id
group by
	m.product_name;

-- 5. Which item was the most popular for each customer?

with cte_times_ordered as (
	select
		s.customer_id,
		s.product_id,
		count(m.product_name) as times_ordered
	from 
		dannys_dinner.sales s left join dannys_dinner.menu m
		on m.product_id = s.product_id
	group by
		s.customer_id,
		s.product_id	
),
cte_times_ordered_ranked as (
	select 
		*,
		rank() over (partition by customer_id order by times_ordered desc)
	from cte_times_ordered
)
select 
	cte.customer_id,
	cte.times_ordered,
	m.product_name
from 
	cte_times_ordered_ranked cte left join dannys_dinner.menu m
	on cte.product_id = m.product_id
where 
	rank = 1
order by 
	cte.customer_id;
	
-- 6. Which item was purchased first by the customer after they became a member?

with cte_ranked_posts_membership_orders as ( -- ranks, per member, the dates of their orders after their joining date 
	select 
		s.*,
		mb.join_date,
		m.product_name,
		rank() over (partition by s.customer_id order by order_date)
	from 
		dannys_dinner.sales s right join dannys_dinner.members mb
		on s.customer_id = mb.customer_id
		left join dannys_dinner.menu m
		on m.product_id = s.product_id
	where 
		s.order_date >= mb.join_date
)
select distinct -- we select distinct pairs of (customer_id, product_name) as it could be possible for a member to order twice the same product on the first order after joining 
	customer_id,
	product_name
from 
	cte_ranked_posts_membership_orders
where 
	rank = 1
order by 
	customer_id;

-- 7. Which item was purchased just before the customer became a member?
-- We assume that, during the joining_date, the member first joins and only then orders. 

with cte_ranked_pre_membership_orders as ( -- ranks, per member, the dates of their orders before their joining date (desc)
	select 
		s.*,
		mb.join_date,
		m.product_name,
		rank() over (partition by s.customer_id order by order_date desc)
	from 
		dannys_dinner.sales s right join dannys_dinner.members mb
		on s.customer_id = mb.customer_id
		left join dannys_dinner.menu m
		on m.product_id = s.product_id	
	where 
		s.order_date < mb.join_date
)
select distinct -- we select distinct pairs of (customer_id, product_name) as it could be possible for a member to order twice the same product on the first order after joining 
	customer_id,
	product_name
from 
	cte_ranked_pre_membership_orders
where 
	rank = 1
order by 
	customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
with cte_pre_membership_orders as (
	select
		s.customer_id,
		s.product_id,
		m.price
	from 
		dannys_dinner.sales s right join dannys_dinner.members mb
		on s.customer_id = mb.customer_id
		left join dannys_dinner.menu m
		on m.product_id = s.product_id	
	where 
		s.order_date < mb.join_date
)
select
	customer_id,
	count(product_id) total_items,
	sum(price) as total_spent
from 
	cte_pre_membership_orders
group by
	customer_id
order by
	customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with cte_points as (
	select
		*,
		case 
			when product_name = 'sushi' then 20*price
			else 10*price
		end as points
	from 
		dannys_dinner.menu
)
select 
	s.customer_id,
	sum(p.points) as total_points	
from
	dannys_dinner.sales s left join cte_points p
	on s.product_id = p.product_id	
group by
	s.customer_id
order by
	customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- 	   not just sushi - how many points do customer A and B have at the end of January?

with cte_points as (
	select
		*,
		case 
			when product_name = 'sushi' then 20*price
			else 10*price
		end as points
	from 
		dannys_dinner.menu
)
select 
	m.customer_id,
	sum(
		case
			when p.product_name = 'sushi' then p.points
			when s.order_date - m.join_date between 0 and 6 then 2*p.points
			else p.points
		end	
	) as total_points		
from
	dannys_dinner.sales s left join cte_points p
	on s.product_id = p.product_id
	right join dannys_dinner.members m
	on m.customer_id = s.customer_id
where 
	s.order_date < '2021-02-01'::date and order_date >= m.join_date
group by
	m.customer_id
order by
	m.customer_id

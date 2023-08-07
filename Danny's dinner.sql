CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 #1. What is the total amount each customer spent at the restaurant?
 select s.customer_id, sum(m.price) as total_amount
 from sales s 
 inner join menu m on s.product_id = m.product_id 
 group by s.customer_id 
 order by s.customer_id ;
 #2. How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date)) as days_counted
from sales s 
group by customer_id 
order by customer_id;
#3. What was the first item from the menu purchased by each customer?
with CTE as
	( select 
		s.customer_id, 
		m.product_name, 
		row_number () over(partition by s.customer_id order by s.order_date) as bought_item_order
	from sales s 
	inner join menu m 
	on s.product_id = m.product_id)
select customer_id, product_name
from CTE
where bought_item_order = 1;
#4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select 
	m.product_name , 
	count(s.product_id) as times_purchased
from sales s
inner join menu m 
on s.product_id = m.product_id 
group by product_name
order by count(s.product_id) desc 
limit 1;
#5. Which item was the most popular for each customer?
with CTE2 as
 	(select 
 		s.customer_id, 
 		m.product_name,
 		count(*) as item_quantity
 	from sales s 
 	inner join menu m
 	on s.product_id=m.product_id
 	group by customer_id, m.product_name),
CTE3 as 
 	(select 
 		customer_id, 
 		product_name,
 		rank() over(partition by customer_id order by item_quantity desc) as ranking
 	from CTE2)
 select 
 	customer_id, 
 	product_name
 from CTE3
 where ranking = 1;
#6. Which item was purchased first by the customer after they became a member? 
with CTE4 as 
	(select 
 		s.customer_id ,
 		min(s.order_date) as first_day_joined
 	from sales s 
 	left join members m2 
 	on s.customer_id = m2.customer_id 
 	where m2.join_date <= s.order_date 
 	group by s.customer_id)
select 
	s.customer_id ,
	m.product_name 
from sales s
inner join menu m 
on s.product_id = m.product_id 
inner join CTE4 
on s.customer_id = CTE4.customer_id
where s.order_date = CTE4.first_day_joined;
#7. Which item was purchased just before the customer became a member?
with CTE5 as 
	(select 
 		s.customer_id ,
 		max(s.order_date) as day_b4_joined
 	from sales s 
 	left join members m2 
 	on s.customer_id = m2.customer_id 
 	where m2.join_date > s.order_date 
 	group by s.customer_id)
select 
	s.customer_id ,
	m.product_name 
from sales s
inner join menu m 
on s.product_id = m.product_id 
inner join CTE5 
on s.customer_id = CTE5.customer_id
where s.order_date = CTE5.day_b4_joined;
#8. What is the total items and amount spent for each member before they became a member?
select 
	s.customer_id ,
	count(*) as total_item_b4_join,
	sum(m.price) as total_spent_b4_join
from sales s 
inner join menu m 
on s.product_id = m.product_id 
inner join members m2 
on s.customer_id = m2.customer_id 
where m2.join_date > s.order_date 
group by s.customer_id; 
#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier – how many points would each customer have?
with CTE6 as 
	(select 
		s.customer_id ,
		m.product_name ,
		case when 
			m.product_name = 'sushi' then m.price * 20
			else m.price * 10
		end as item_point
	from sales s
	inner join menu m
	on s.product_id = m.product_id)
select 
	customer_id, 
	sum(item_point) as total
from CTE6
group by customer_id;
#10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi – how many points do customer A and B have at the end of January?
with CT7 as 	
	(select 
		s.customer_id ,
		m.product_name ,
		m.price ,
		m2.join_date ,
		s.order_date ,
		case 
			when m.product_name = 'sushi' then m.price * 20
			when m.product_name = 'ramen' and datediff(s.order_date, m2.join_date) + 1 <= 7 and datediff(s.order_date, m2.join_date) + 1 >= 0 then m.price * 20
			when m.product_name = 'curry' and datediff(s.order_date, m2.join_date) + 1 <= 7 and datediff(s.order_date, m2.join_date) + 1 >= 0 then m.price * 20
			else m.price * 10
		end as item_point	
	from sales s
	inner join menu m
	on s.product_id = m.product_id
	left join members m2
	on s.customer_id = m2.customer_id)
select 
	customer_id ,
	sum(item_point) as total
from CT7
where customer_id != 'C'and month(order_date) = 1
group by customer_id ;
 #Bonus Question
 	#1.Join all the things
  select
		s.customer_id,
		s.order_date,
		m.product_name,
		m.price,
		case 
			when s.order_date < mem.join_date or mem.join_date is null then 'N'
			when s.order_date >= mem.join_date then 'Y'
		 end as 'member'
  from sales s
  left join menu m
  on s.product_id = m.product_id
  left join members mem
  on s.customer_id = mem.customer_id;

  	#2.Rank all the things
  with CTE8 as
  (
	  select 
			s.customer_id,
			s.order_date,
			m.product_name,
			m.price,
			case 
				when s.order_date < m2.join_date or m2.join_date is null then 'N'
				when s.order_date >= m2.join_date then 'Y'
			 end as 'member'
	  from sales s
	  left join menu m
	  on s.product_id = m.product_id
	  left join members m2
	  on s.customer_id = m2.customer_id
  )
  select 
		customer_id,
		order_date,
		product_name,
		price,
		member,
		case 
			when member = 'N' then null
			when member = 'Y' then rank() over(partition by customer_id, member order by order_date)
		 end as ranking
  from CTE8;

	
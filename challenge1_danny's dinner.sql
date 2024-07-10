select * from members;
select*from menu;
select * from sales;



-- Q1. what is the total amount each customer spend at the restaurant?
-- sol 
-- step 1 find out which food item is purchased by each customer with price
select s.*,m.product_name,m.price
from sales s
join menu m on s.product_id = m.product_id;

-- step 2 find the total amount each customer spend at the restaurant with the help of step 1
select x.customer_id,sum(price)
from(select s.*,m.product_name,m.price
from sales s
join menu m on s.product_id = m.product_id) x 
group by 1;




-- Q2 How many days has each customer visited the restaurant?
-- sol
-- find the count of distinct order_date and group by customer_id

select s.customer_id,count(distinct order_date)
from sales s
group by s.customer_id;




-- Q3. What was the first item from the menu purchased by each customer?
-- sol
-- step 1-join table menu and sales to find out which customer buy which item

select s.*,m.product_name,m.price
from sales s
join menu m on s.product_id = m.product_id;

-- step 2-now apply row_numer window function to find which item is first bought by each customer and use table with WITH CLAUSE to fetch details

with first_bought as (select s.*,m.product_name,m.price,
row_number()over(partition by s.customer_id order by s.order_date) as rn
from sales s
join menu m on s.product_id = m.product_id)

select customer_id,product_name
from first_bought
where rn=1;





-- Q4 What is the most purchased item on the menu and how many times was it purchased by all customers?
-- sol


select m.product_id, m.product_name,count(m.product_id) as no_of_times
from sales s
join menu m on s.product_id = m.product_id
group by 1,2
order by 3 desc limit 1;

--  the most purchased item on the menu and how many times was it purchased by each customer?
select sa.customer_id,x.product_name ,count(sa.product_id)
from sales sa
join(select m.product_id, m.product_name,count(m.product_id) as count
from sales s
join menu m on s.product_id = m.product_id
group by 1,2
order by 3 desc limit 1) x
on sa.product_id = x.product_id
group by 1,2;




-- Q5.Which item was the most popular for each customer?
-- sol
-- step1: join table sales and menu 

select s.*,m.product_name
from sales s
join menu m on s.product_id = m.product_id;

-- step2: apply rank() window function to give rank to food items and use it with WITH CLAUSE to filter out the popular item

with items as (select s.customer_id,m.product_name,count(s.product_id),
dense_rank()over(partition by s.customer_id order by count(m.product_id) desc) as rn
from sales s
join menu m on s.product_id = m.product_id
group by s.customer_id,m.product_name)

select items.customer_id,items.product_name as popular_item
from items
where rn = 1;




-- Q6. Which item was purchased first by the customer after they became a member?
-- sol

-- step:1 join sales,menu,members table together and apply row_number window function
-- step:2 use the obtained table in with clause to fiter the data

with x as (select s.customer_id,s.order_date,s.product_id,m.product_name,ms.join_date,row_number()over(partition by s.customer_id order by s.order_date) as rn
from sales s
join menu m
on s.product_id = m.product_id
join members ms on s.customer_id = ms.customer_id
where s.order_date >= ms.join_date
order by s.customer_id,s.order_date)

select x.customer_id,x.product_name as first_item_purchased
from x
where x.rn=1;




-- Q7.Which item was purchased just before the customer became a member?
-- sol

-- step:1 join sales,menu,members table together and apply row_number window function
-- step:2 use the obtained table in with clause to fiter the data

with x as (select s.customer_id,s.order_date,s.product_id,m.product_name,ms.join_date,dense_rank()over(partition by s.customer_id order by s.order_date desc) as rn
from sales s
join menu m
on s.product_id = m.product_id
join members ms on s.customer_id = ms.customer_id
where s.order_date < ms.join_date
order by s.customer_id,s.order_date)

select x.customer_id,x.product_name as first_item_purchased
from x
where x.rn=1;





-- Q8. What is the total items and amount spent for each member before they became a member?
-- sol

with x as (select s.customer_id,s.order_date,s.product_id,m.product_name,ms.join_date,m.price
from sales s
join menu m
on s.product_id = m.product_id
join members ms on s.customer_id = ms.customer_id
where s.order_date < ms.join_date
order by s.customer_id,s.order_date)

select x.customer_id,count(x.product_id) as to_item,sum(x.price) as to_price
from x
group by x.customer_id
order by x.customer_id;




-- Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- sol

-- first find the points achieve by each customer as per visit

select s.*,m.product_name,m.price,
case when m.product_name='sushi' then m.price*2*10
     else m.price*10
	end as points
from sales s
join menu m on s.product_id = m.product_id;

-- now find to_points each customer have
select customer_id ,sum(points) as to_points
from(select s.*,m.product_name,m.price,
     case when m.product_name='sushi' then m.price*2*10
          else m.price*10
	   end as points
    from sales s
    join menu m on s.product_id = m.product_id) x
group by customer_id;




-- Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- sol

-- step1:join sales,menu,members table and find data from join_date to till 7days

select s.customer_id,s.order_date,m.product_name,m.price,ms.join_date,
       case when order_date between join_date and adddate(join_date,7) then m.price*2*10
             when m.product_name='sushi' then m.price*2*10
            else 10*m.price
		end as points
from sales s
join menu m on s.product_id = m.product_id
join members ms on s.customer_id=ms.customer_id
where order_date < '2021-02-01'
order by 1,2;

-- fiter the data using subquery

select x.customer_id , sum(x.points)
from(select s.customer_id,s.order_date,m.product_name,m.price,ms.join_date,
       case when order_date between join_date and adddate(join_date,7) then m.price*2*10
            when m.product_name='sushi' then m.price*2*10
            else 10*m.price
		end as points
from sales s
join menu m on s.product_id = m.product_id
join members ms on s.customer_id=ms.customer_id
where order_date < '2021-02-01'
order by 1,2) x
     group by 1
     order by 1;
     
     
     
     
     
-- Bonus question

-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
-- Recreated table



with cte as (select s.customer_id,s.order_date,m.price,
case when s.order_date >=ms.join_date and s.customer_id = ms.customer_id then 'Y'
     else 'N'
     end as member
from sales s
join menu m on s.product_id = m.product_id
left join members ms on ms.customer_id = s.customer_id)


--  the ranking of customer products, but  purposely does not need
-- the ranking for non-member purchases so danny expects null ranking values for the records when customers are not yet part of the loyalty program.


select *,
 case when cte.member = 'Y' then  dense_rank()over(partition by cte.customer_id,cte.member order by cte.order_date)
	   when cte.member = 'N' then 'null'
      end as ranking
from cte;







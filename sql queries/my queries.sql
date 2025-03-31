--creating tables

create table warehouse
(
warehouse_id int primary key,
region_id int,
city varchar(15)
);

create table customer 
(
customer_id	int primary key,
customer_name varchar(25)
);

create table employee
(
employee_id	int primary key,
employee_name varchar(30),
employee_hiredate date,
employee_job_title varchar(50),
warehouse_id int 
);

create table order_details
(
order_details_id int primary key,
product_id	int,
quantity int,
per_unit_price	float,
total_sales	float,
order_status varchar(10),
order_id int
);

alter table order_details
alter column product_id type varchar(10)

create table orders
(
order_id int primary key,
order_date date,
customer_id int
);

create table product
(
product_id int primary key,
product_name varchar(60),	
category_name varchar(15),	
cost_price float,
selling_price float,
profit float
);

alter table product
alter column product_id type varchar(10)

create table region
(
region_id int primary key,
region_name	varchar(20),
country_name varchar(30),	
city varchar(15)
);

--establishing Entity relationships

alter table order_details
add constraint fk_order_details
foreign key (order_id)
references orders(order_id)

alter table order_details
add constraint fk_product
foreign key (product_id)
references product(product_id)

alter table orders
add constraint fk_customers
foreign key (customer_id)
references customer(customer_id)

alter table employee
add constraint fk_warehouse
foreign key (warehouse_id)
references warehouse(warehouse_id)

alter table warehouse
add constraint fk_region
foreign key (region_id)
references region(region_id)

select * from customer
select * from orders
select * from order_details
select * from product
select * from warehouse
select * from region
select * from employee

-- checking duplicate values

with duplicate_cte as
(
select *,
rank() over(partition by employee_id, employee_name, employee_hiredate, employee_job_title, warehouse_id)
from employee
)
select * from duplicate_cte
where rank > 1

-- checking null values

select * from employee
where employee_id is null or
	  employee_name is null or
	  employee_hiredate is null or
	  employee_job_title is null or
	  warehouse_id is null 
	  
--Business Problems

--Beginner Level

--Sales Analysis

--Q1. Calculate total sales, average sales per day, and total revenue by product category.

select 
	p.category_name as product_category,
	sum(total_sales) as total_revenue, 
	avg(total_sales) as avg_sales_per_day, 
	count(distinct order_date) as number_of_days 
	from order_details od
Join product p on p.product_id = od.product_id
Join orders o on od.order_id = o.order_id
group by p.category_name

--Q2. Find the top 5 best-selling products of the month.

select distinct category_name, sum(total_sales) as total_profit from order_details od
join product p on p.product_id = od.product_id
group by category_name
order by total_profit desc
limit 5

-- Q3. Calculate the profit made from each product.

select 
		product_name,
		sum(profit) as total_profit
from product
group by product_name

--Customer insights

--Q4. Identify new customers acquired each month.

select 
	to_char(min(o.order_date), 'YYYY-MM') as acquired_month,
	c.customer_name, 
	count(c.customer_id) as new_customers
from orders o
join  customer c on c.customer_id = o.customer_id
group by c.customer_name
order by acquired_month

--Q5. Find customers who haven’t placed an order in the year 2016.

--select c.customer_id, c.customer_name from customer c
--left join orders o on c.customer_id = o.customer_id
--where o.order_date is null or
--(o.order_date < Now() - Interval '6 months')

select 
	c.customer_id, 
	c.customer_name
from customer c
left join orders o on c.customer_id = o.customer_id
where o.order_date is null or
	  (o.order_date between '2016-01-01' and '2016-12-31')

--Q6. Find customers who have placed an order in the last 6 months.

select 
	c.customer_id, 
	c.customer_name, 
	max(o.order_date) as last_order_date
from customer c
join orders o on c.customer_id = o.customer_id
where (o.order_date >= Now() - Interval '6 months')
group by 1,2

--Q7. Find the number of orders placed by each customer.

select c.customer_name,
	   count(o.order_id) as total_orders
from customer c 
join orders o on c.customer_id = o.customer_id
group by 1

-- Q8. Get the 10 most recent orders with customer names and order dates.

select c.customer_name,
	   o.order_date
from customer c
join orders o on c.customer_id = o.customer_id
group by 1, 2
order by o.order_date desc
limit 10

-- Q9. Find categories that have less than 50 items in stock.

select 
	p.product_name, 
	od.quantity 
from product p
join order_details od on p.product_id = od.product_id
where od.quantity < 50

-- Employee performances

-- Q10. Track Employees by Hire Date and Job Title

Select 
	  employee_job_title,
	  count(employee_id) as total_employees,
	  Extract(year from employee_hiredate) as hire_date
from employee
group by 1, 3
order by 3 desc

-- Q11. Employee Tenure and Job Title Analysis

select 
		employee_name,
		employee_job_title,
		extract(year from age(employee_hiredate)) as tenure_years
from employee
order by 3 desc

--Sales Trend Analysis

-- Q12. Analyze monthly and yearly sales trends to identify seasonality.

select 
 		extract(year from o.order_date) as year,
		extract(month from o.order_date) as month,
		sum(od.total_sales) as total_sales,
		sum(sum(od.total_sales)) over(partition by extract(year from o.order_date)) as yearly_sales 
from order_details od
join orders o on od.order_id = o.order_id
group by 1,2
order by 1 asc, 2 asc 

-- Q13. Calculate total revenue per quarter for each year. 

select 
		extract(year from order_date) as year,
		extract(quarter from order_date) as quarter,
		sum(total_sales) as total_revenue
from orders	o
join order_details od on o.order_id = od.order_id
group by 1,2
order by 1 asc

-- Customer Segmentation

-- Q14. Segment customers based on purchase frequency and average order value.

select 
		c.customer_id,
		c.customer_name,
		count(o.order_id) as purchase_frequency,
		sum(od.total_sales) / count(o.order_id) as avg_order_value,
case
		when count(o.order_id) >=1 and sum(od.total_sales) / count(o.order_id) > 200000 then 'High Frequent Buyer'
		when sum(od.total_sales) / count(o.order_id) between 100000 and 200000 then 'High Infrequent Buyer'
		else 'Low Frequent Buyer'
end as customer_segment
from customer c
join orders o on o.customer_id = c.customer_id
join order_details od on o.order_id = od.order_id
group by 1,2
order by 4 desc

-- Q15. Identify high-value customers and their purchasing behavior.

select 
 		c.customer_id,
		c.customer_name, 
		count(o.order_id) as total_orders,
		sum(od.total_sales) as total_revenue,
		avg(od.total_sales) as avg_order_value,
		ROUND(AVG(od.quantity), 2) AS avg_quantity_per_order
from customer c 
join orders o on c.customer_id = o.customer_id
join order_details od on od.order_id = o.order_id
group by 1,2
having sum(od.total_sales) > 150000
order by total_revenue desc

-- Inventory Turn over

-- Q16. Calculate inventory turnover ratio and average days to sell inventory.

-- Formula: inventory turn ratio = cost of goods sold(cogs) / average inventory
-- cogs = sum(quantity * cost price)
-- average inventory = avg(cost price * quantity)
--average days to sell = 365/itr

select 
		p.category_name,
		sum(od.quantity * p.cost_price) as cogs,
		avg(p.cost_price * od.quantity) as average_inventory,
	    (sum(od.quantity * p.cost_price) / nullif(avg(p.cost_price * od.quantity), 0)) as inventory_turn_ratio,
        (365 / nullif((sum(od.quantity * p.cost_price) / nullif(avg(p.cost_price * od.quantity), 0)), 0)) as average_days_to_sell
from product p
join order_details od on p.product_id = od.product_id
group by 1
order by 4 desc

-- Q17. Identify slow-moving or dead stock products.

select
		p.product_name,
		p.category_name,
		sum(od.quantity) as total_units_sold,
		sum(od.total_sales) as total_revenue,
		(sum(od.quantity * p.cost_price) / nullif(avg(p.cost_price * od.quantity), 0)) as inventory_turn_ratio
from product p 
join order_details od on p.product_id = od.product_id
group by 1,2
having 
		sum(od.quantity) is null or
		sum(od.quantity) < 50 or 
		(sum(od.quantity * p.cost_price) / nullif(avg(p.cost_price * od.quantity), 0)) < 1
order by 3, 5 desc

-- Finacial Analysis

-- Q18. Calculate the profit margin and EBITDA for each product category.

--formula: profit margin = (profit)/(total sales) *100
--EBITDA = total sales - cogs 
--cogs = quantity * cost price

SELECT 
    p.category_name,
    SUM(od.total_sales) AS total_revenue,
    SUM(od.quantity * p.cost_price) AS cogs,
    SUM((p.selling_price - p.cost_price) * od.quantity) AS total_profit,
    ROUND(CAST((SUM((p.selling_price - p.cost_price) * od.quantity) / NULLIF(SUM(od.total_sales), 0)) * 100 AS numeric), 2) AS profit_margin,
    SUM(od.total_sales) - SUM(od.quantity * p.cost_price) AS ebitda
FROM 
    product p
JOIN 
    order_details od ON p.product_id = od.product_id
GROUP BY 1
ORDER BY 5 DESC;

-- Q19. Identify the number of warehouses in each region

select 
		r.region_name,
		count(warehouse_id) as total_warehouse
from region r
join warehouse w on r.region_id = w.region_id
group by 1

-- Q20. Analyze the distribution of employees across different cities.

select 
		w.city ,
		r.region_name,
		count(e.employee_id) as total_employess
from warehouse w
join employee e on e.warehouse_id = w.warehouse_id
join region r on r.region_id = w.region_id
group by 1, 2
order by 3 desc

-- Q21. Identify employees hired in each region in the year 2016. 

select 
  extract (year from e.employee_hiredate) as year,
  extract (month from e.employee_hiredate) as month,
  r.city,
  r.region_name,
  count(e.employee_id) as total_employees_hired
from employee e
join warehouse w on e.warehouse_id = w.warehouse_id
join region r on r.region_id = w.region_id
where e.employee_hiredate between '2016-01-01' and '2016-12-31'
group by 1, 2, 3, 4
order by 5 desc

-- Q22. Employee Distribution Across Regions

select 
		r.region_name,
		count(e.employee_id) as total_employees,
		count(distinct w.warehouse_id) as total_warehouses
from warehouse w
join employee e on w.warehouse_id = e.warehouse_id
join region r on r.region_id = w.region_id
group by r.region_name
order by 2,3

 










		






		




		
























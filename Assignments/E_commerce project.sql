USE E_ticaret


--market_fact
update market_fact set Ord_ID = SUBSTRING(Ord_ID, 5, 10)
alter table market_fact alter COLUMN Ord_ID int
update market_fact set Prod_ID = SUBSTRING(Prod_ID, 6, 10)
alter table market_fact alter COLUMN Prod_ID int
update market_fact set Ship_ID = SUBSTRING(Ship_ID, 5, 10)
alter table market_fact alter COLUMN Ship_ID int
update market_fact set Cust_ID = SUBSTRING(Cust_ID, 6, 10)
alter table market_fact alter COLUMN Cust_ID int

--orders_dimen
update orders_dimen set Ord_ID = SUBSTRING(Ord_ID, 5, 10)
alter table orders_dimen alter COLUMN Ord_ID int

--prod_dimen

update prod_dimen set Prod_ID = SUBSTRING(Prod_ID, 6, 10)
alter table prod_dimen alter COLUMN Prod_ID int

--shipping_dimen
update shipping_dimen set Ship_ID = SUBSTRING(Ship_ID, 5, 10)
alter table shipping_dimen alter COLUMN Ship_ID int

--cust_dimen
update cust_dimen set Cust_ID = SUBSTRING(Cust_ID, 6, 10)
alter table cust_dimen alter COLUMN Cust_ID int


-- /1*creating table 'combined_table'

SELECT	* 
INTO	dbo.combined_table
FROM
(
SELECT	M.*, C.Customer_Name, C.Customer_Segment, C.Province, C.Region, O.Order_Date, O.Order_Priority, S.Ship_Mode, S.Ship_Date, P.Product_Category, P.Product_Sub_Category
FROM		dbo.market_fact AS M
LEFT JOIN	dbo.cust_dimen AS C
ON			M.Cust_ID = C.Cust_ID
LEFT JOIN	dbo.orders_dimen AS O
ON			M.Ord_ID = O.Ord_ID
LEFT JOIN	dbo.shipping_dimen AS S
ON			M.Ship_ID = S.Ship_ID
LEFT JOIN	dbo.prod_dimen AS P
ON			M.Prod_ID = P.Prod_ID
) AS T
;

SELECT * FROM dbo.combined_table;

--2. Find the top 3 customers who have the maximum count of orders.
SELECT	TOP 3 Customer_Name, COUNT(Ord_ID) AS order_count
FROM	combined_table
GROUP BY Customer_Name
ORDER BY 2 DESC
;
--3. Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
SELECT	*, DATEDIFF(day, Order_Date, Ship_Date) AS DaysTakenForDelivery
FROM	dbo.combined_table
ORDER BY 1 DESC;
--
SELECT	Order_ID, DATEDIFF(day, Order_Date, Ship_Date) AS DaysTakenForDelivery
FROM	dbo.combined_table
ORDER BY 2 DESC;
--
ALTER TABLE dbo.combined_table
ADD DaysTakenForDelivery AS (DATEDIFF(day, Order_Date, Ship_Date))
;
---
SELECT * FROM dbo.combined_table;
--4. Find the customer whose order took the maximum time to get delivered
SELECT	TOP 1 Customer_Name, MAX(DaysTakenForDelivery) AS MaxDeliveryDays
FROM	dbo.combined_table
GROUP BY Customer_Name
ORDER BY 2 DESC
;
--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
SELECT MONTH(Order_Date) month, 
      DATENAME(month,Order_Date) month_name, 
      COUNT(DISTINCT cust_ID) cust_num
FROM combined_table A 
WHERE 
  EXISTS (
    SELECT  cust_ID
    FROM combined_table b
    WHERE MONTH(Order_Date) = 1  
    AND YEAR(Order_Date)=2011
    AND A.Cust_ID = B.Cust_ID
  )
AND YEAR(Order_Date)=2011
GROUP BY MONTH(Order_Date) , datename(month,Order_Date) 
Order by month
--6. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.
SELECT	Cust_ID,
		FIRST_VALUE(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS FirstPurchase
FROM	dbo.combined_table
ORDER BY 1
;
-----
SELECT	A.Order_Date AS FirstPurchase
FROM	(
		SELECT	ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Row#,
		Cust_ID,
		Order_Date
		FROM	dbo.combined_table
		) AS A
WHERE	A.Row# = 1
;
------
SELECT	Cust_ID, Order_Date,
		ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Row#
FROM	dbo.combined_table
GROUP BY Cust_ID, Order_Date
;
------
SELECT	ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Row#,
		Cust_ID,
		Order_Date
FROM	dbo.combined_table
;
------
SELECT	A.Order_Date AS ThirdPurchase
FROM	(
		SELECT	ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Row#,
		Cust_ID,
		Order_Date
		FROM	dbo.combined_table
		) AS A
WHERE	A.Row# = 3
;
-------
SELECT *, DATEDIFF(day, F.FirstPurchase, T.ThirdPurchase) AS ElapsedTimeFirstThird
FROM
(
SELECT	A.Cust_ID, A.Order_Date AS FirstPurchase
FROM	(
		SELECT	ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Row#,
		Cust_ID,
		Order_Date
		FROM	dbo.combined_table
		) AS A
WHERE	A.Row# = 1
) AS F,
(
SELECT	A.Cust_ID, A.Order_Date AS ThirdPurchase
FROM	(
		SELECT	ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Row#,
		Cust_ID,
		Order_Date
		FROM	dbo.combined_table
		) AS A
WHERE	A.Row# = 3
) AS T
WHERE	F.Cust_ID = T.Cust_ID
;
--7. Write a query that returns customers who purchased both product 11 and product 14, as well as the ratio of these products to the total number of products purchased by the customer.
SELECT	DISTINCT Customer_Name
FROM	dbo.combined_table
WHERE	Prod_ID IN (11, 14)
; 
-------
SELECT	DISTINCT Customer_Name
FROM	dbo.combined_table
WHERE	Prod_ID = 11
;  
----
SELECT	DISTINCT Customer_Name
FROM	dbo.combined_table
WHERE	Prod_ID = 14
; 
------
SELECT	DISTINCT Cust_ID
FROM	dbo.combined_table
WHERE	Prod_ID = 11
INTERSECT
SELECT	DISTINCT Cust_ID
FROM	dbo.combined_table
WHERE	Prod_ID = 14
; 
--------
SELECT *
FROM	dbo.combined_table
WHERE Cust_ID IN
(
SELECT	DISTINCT Cust_ID
FROM	dbo.combined_table
WHERE	Prod_ID = 11
INTERSECT
SELECT	DISTINCT Cust_ID
FROM	dbo.combined_table
WHERE	Prod_ID = 14
)
ORDER BY Cust_ID
;
---------------
SELECT	DISTINCT Cust_ID, 
		COUNT(Prod_ID) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID) AS TotalNumberOfProductPurchased,
		ROUND((2.0/(COUNT(Prod_ID) OVER (PARTITION BY Cust_ID ORDER BY Cust_ID))), 3) AS RatioSaidProdToTotal
FROM	dbo.combined_table
WHERE Cust_ID IN
(
SELECT	DISTINCT Cust_ID
FROM	dbo.combined_table
WHERE	Prod_ID= 11
INTERSECT
SELECT	DISTINCT Cust_ID
FROM	dbo.combined_table
WHERE	Prod_ID = 14
)
;
--CUSTOMER SEGMENTATION
--1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
CREATE VIEW customer_log AS
(
SELECT cust_id, 
      YEAR(Order_Date) as order_year, 
      MONTH(Order_Date) as order_month
FROM combined_table
GROUP BY cust_id, YEAR(Order_Date), MONTH(Order_Date) 
)
--2.Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning  business)
CREATE VIEW montly_visits AS 
(
SELECT	Cust_ID,
		Customer_Name,
		YEAR(Order_Date) Years, 
		DATENAME(MONTH,Order_Date) Months,
		COUNT(Order_Date) Monthly_visit
FROM combined_table
GROUP BY Cust_ID, Customer_Name, YEAR(Order_Date) , DATENAME(MONTH,Order_Date)
)
----
SELECT *
FROM montly_visits
--3. For each visit of customers, create the next month of the visit as a separate column.
CREATE VIEW Next_Visit AS
(
SELECT	*,
		LEAD(CURRENT_MONTH, 1) OVER (PARTITION BY Cust_ID ORDER BY Current_Month) Next_Visit_Month
FROM
	(SELECT *,
	DENSE_RANK() OVER(ORDER BY [years] , [months]) Current_Month
	FROM montly_visits
	) t1
) 
-----
SELECT * 
FROM Next_Visit
--4. Calculate monthly time gap between two consecutive visits by each customer.
CREATE VIEW time_gap As 
(
SELECT Cust_ID, Order_Date, 
second_order , 
DATEDIFF(MONTH,Order_Date,second_order) time_gap
FROM
	(SELECT  Cust_ID, 
          Order_Date,	
          MIN(Order_date) over(Partition by Cust_ID) first_order_date,	 
          lead(Order_Date, 1) over(partition by cust_ID order by order_date) second_order,
          DENSE_RANK() over(Partition by Cust_ID order by order_date) order_datez
  FROM combined_table
	) T
WHERE DATEDIFF(MONTH,Order_Date,second_order) >0
) 
--5.Categorise customers using average time gaps. Choose the most fitted labeling model for you.
For example: 
Labeled as “churn” if the customer hasn't made another purchase for the months since they made their first purchase.
Labeled as “regular” if the customer has made a purchase every month.
Etc.*/

SELECT *
FROM time_gap
---
SELECT Cust_ID, 
        AVG(time_gap) avg_time_gap
FROM time_gap
GROUP BY Cust_ID 
---
SELECT Cust_ID, 
      avg_time_gap,
      CASE  WHEN avg_time_gap = 1 THEN 'Retained'
            WHEN avg_time_gap > 1 THEN 'Irregular'
            WHEN avg_time_gap IS NULL THEN 'Churn'
            ELSE 'UNKNOWN DATA' 
            END Customer_Lebels
FROM (
     SELECT Cust_ID, 
        AVG(time_gap) avg_time_gap
      FROM time_gap
      GROUP BY Cust_ID 
) t1


---------------MONTH-WISE RETENTÝON RATE--------------------


/* 1. Find the number of customers retained month-wise. (You can use time gaps)
SELECT DISTINCT YEAR(order_date) [year], 
                MONTH(order_date) [month],
                DATENAME(month,order_date) [month_name],
                COUNT(cust_ID) OVER (PARTITION BY year(order_date), month(order_date) order by year(order_date), month(order_date)  ) num_cust
FROM combined_table
----------------------------------------------------------------
/*2. Calculate the month-wise retention rate.
CREATE VIEW t1 AS
(
SELECT DISTINCT YEAR(order_date) [year], 
                MONTH(order_date) [month],
                DATENAME(month,order_date) [month_name],
                COUNT(cust_ID) OVER (PARTITION BY year(order_date), month(order_date) order by year(order_date), month(order_date)  ) num_cust
FROM combined_table
) 
 
SELECT[year],
      [month_name],
      [num_cust],
      LEAD(num_cust,1) OVER (ORDER BY [year], [month] ) as next_num,
      FORMAT(num_cust*1.0*100/(lead(num_cust,1) over (order by year, month, num_cust)),'N2') ratio
FROM t1
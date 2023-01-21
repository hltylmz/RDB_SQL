



--9. Write a query to pull the first 10 rows and all columns from the product table that have a list_price greater than or equal to 3000.


SELECT TOP 10 * 
FROM	product.product
WHERE	list_price >= 3000
ORDER BY list_price desc






--10. Write a query to pull the first 5 rows and all columns from the product table that have a list_price less than 3000.



SELECT TOP 5 * 
FROM	product.product
WHERE	list_price < 3000
ORDER BY list_price desc






--11. Find all customer last names that start with 'B' and end with 's'.


SELECT *
FROM	sale.customer
WHERE	last_name LIKE 'B%s'




--12. Use the customer table to find all information regarding customers whose address is Allen or Buffalo or Boston or Berkeley.


SELECT *
FROM	sale.customer
WHERE	city = 'Allen' 
		OR
		city = 'Buffalo' 
		OR 
		city = 'Boston' 
		OR 
		city = 'Berkeley'

		-------



SELECT *
FROM sale.customer
WHERE city IN ('Allen', 'Buffalo', 'Boston', 'Berkeley')




--Write a query that returns the name of the streets, where the third character of the streets is numeric.






SELECT	street, SUBSTRING(street, 3, 1) third_char, ISNUMERIC (SUBSTRING(street, 3, 1)) ISNUM
FROM	sale.customer
WHERE	ISNUMERIC (SUBSTRING(street, 3, 1)) = 1
ORDER BY 2

----


SELECT street, SUBSTRING(street, 3, 1) AS third_char
FROM sale.customer
WHERE SUBSTRING(street, 3, 1) LIKE '%[0-9]%'
GROUP BY street ;

----


SELECT street, SUBSTRING(street, 3, 1) third_char
FROM sale.customer
WHERE street like '__[0-9]%'




--Add a new column to the customers table that contains the customers' contact information. 
--If the phone is not null, the phone information will be printed, if not, the email information will be printed.


SELECT	phone, email,  ISNULL (phone, email)  as contact_info,  COALESCE (phone, email, street+city+state)  as contact_info
FROM	sale.customer
ORDER BY 3




 --Split the mail addresses into two parts from ‘@’, and place them in separate columns.



SELECT	email , 
		SUBSTRING(email, 1, CHARINDEX('@', email)-1) AS before_@ ,
		SUBSTRING(email, CHARINDEX('@', email)+1, 50) AS after_@
FROM sale.customer


-----

SELECT email, 
        SUBSTRING(email,1,(CHARINDEX('@', email)-1)) as email_name,
        SUBSTRING(email,(CHARINDEX('@', email)+1), (LEN(email) - (CHARINDEX('@', email)))) as email_provider 
FROM sale.customer;


----


SELECT LEFT(email, CHARINDEX('@', email) - 1) AS username,
       RIGHT(email, LEN(email) - CHARINDEX('@', email)) AS domain
FROM sale.customer;




-----

SELECT	email, CHARINDEX ('@', email) index@,
		SUBSTRING(email, 1, CHARINDEX ('@', email)-1),
		LEN(email),
		SUBSTRING(email, CHARINDEX ('@', email)+1, LEN(email))
		
FROM	sale.customer

-------------


SELECT	A.customer_id, B.first_name, b.last_name, COUNT(order_id) CNT_ORDER
FROM	sale.orders AS A
		INNER JOIN
		sale.customer AS B
		ON	A.customer_id = B.customer_id
GROUP BY A.customer_id, B.first_name, B.last_name







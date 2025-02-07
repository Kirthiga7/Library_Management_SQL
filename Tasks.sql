

--T1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic',
--6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn,book_title,category,rental_price,status,author,publisher)
values( '978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic',6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

--T2. Update an Existing Member's Address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

--T3. Delete a Record from the Issued Status Table -- Objective: Delete the record with 
--issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id='IS121';

/*T4. Retrieve All Books Issued by a Specific Employee -- Objective: Select all 
books issued by the employee with emp_id = 'E101'. */
SELECT issued_book_name
FROM issued_status
where issued_emp_id = 'E101';

--T5: List Members Who Have Issued More Than One Book and list the numbers 
SELECT issued_emp_id, count(issued_id) as total_issued
FROM issued_status
GROUP BY issued_emp_id
having count(issued_id) >1
order by total_issued;

/*CTAS (Create Table As Select)
T6: Create Summary Tables: Used CTAS to generate new tables based on query 
results each book and total book_issued_cnt**/
CREATE TABLE book_counts
AS
SELECT bk.isbn,bk.book_title, count(ist.issued_id) FROM books bk
JOIN issued_status ist
ON bk.isbn=ist.issued_book_isbn
GROUP BY 1;

SELECT * FROM book_counts;

--T7. Retrieve All Books in a Specific Category:
SELECT book_title
FROM books
WHERE category='History';

--T8. Find Total Rental Income by Category:
SELECT category, sum(rental_price) as total_price, count(*)
FROM books
GROUP BY category
order by total_price desc;

--Inserting Latest Values
INSERT INTO members
VALUES
('C120','Hendry','22 Bad St','2025-01-09'),
('C122','Peter','22 Good St','2024-12-06');

--T9. List Members Who Registered in the Last 180 Days
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';
--From today date we are minus the interval of 180 days

--T10. List Employees with Their Branch Manager's Name and their branch details
SELECT e.emp_name, e2.emp_name as manager, b.*
FROM branch b
JOIN employee e
ON b.branch_id = e.branch_id
JOIN employee e2
ON b.manager_id = e2.emp_id;

--T11. Create a Table of Books with Rental Price Above a Certain Threshold eg:7
DROP TABLE IF EXISTS book_price_7_and_above;
CREATE TABLE book_price_7_and_above
AS
SELECT * FROM books
WHERE rental_price >=7
order by rental_price;

SELECT * FROM book_price_7_and_above;

--T12.  Retrieve the List of Books Not Yet Returned
SELECT DISTINCT i.issued_book_name
FROM issued_status i
LEFT JOIN return_status r
ON i.issued_id=r.issued_id
WHERE r.return_id IS NULL;

/* T13: Identify Members with Overdue Books
Write a query to identify members who have overdue books 
(assume a 30-day return period). Display the member's_id,
member's name, book title, issue date, and days overdue. */
SELECT member_id, 
	member_name,
	book_title,
	i.issued_date,
	CURRENT_DATE - issued_date as overdue
FROM members m
JOIN issued_status i
ON i.issued_member_id = m.member_id
JOIN books b
ON i.issued_book_isbn = b.isbn
LEFT JOIN return_status r
ON i.issued_id = r.issued_id
WHERE return_date IS NULL
AND CURRENT_DATE - issued_date > 30
ORDER BY 1;

/*T14: Update Book Status on Return: Write a query to 
update the status of books in the books table to "Yes" 
when they are returned (based on entries in the return_status table). */
--Doing manually
SELECT * FROM books
WHERE isbn='978-0-451-52994-2';

UPDATE books
SET status='No'
WHERE isbn='978-0-451-52994-2';

SELECT * FROM issued_status
WHERE issued_book_isbn='978-0-451-52994-2';

SELECT * FROM return_status
WHERE issued_id='IS130';

INSERT INTO return_status(return_id,issued_id,return_date,book_quality)
VALUES
('RS125','IS130',CURRENT_DATE,'Good');

UPDATE books
SET status='Yes'
WHERE isbn='978-0-451-52994-2';

--By using Stored Procedure
/*
CREATE OR REPLACE PROCEDURE procedure_name(parameters)
LANGUAGE plpgsql
AS $$

DECLARE
        --all the variable
BEGIN
        --logic/code

END;
$$
*/
CREATE OR REPLACE PROCEDURE update_status(p_return_id VARCHAR(10),p_issued_id VARCHAR(10),book_quality VARCHAR(15))
LANGUAGE plpgsql
AS $$

DECLARE
     v_isbn VARCHAR(20);
	 v_book_name VARCHAR(60);
BEGIN
     --Inserting into return based on users input
	 INSERT INTO return_status(return_id ,issued_id ,return_date,book_quality )
     VALUES
     (p_return_id,p_issued_id,CURRENT_DATE,book_quality);  

	 SELECT 
	    issued_book_isbn ,
	    issued_book_name
	    INTO 
		v_isbn,
		v_book_name
	    FROM issued_status
	    WHERE issued_id = p_issued_id;
	 
	 UPDATE books
     SET status='yes'
     WHERE isbn= v_isbn; 
 RAISE NOTICE 'Thank You for returning the book: %', v_book_name;
END;
$$
--Calling procedure
CALL update_status('RS138','IS135','Good');

select * from books
where isbn='978-0-375-41398-8';
select * from issued_status
where issued_book_isbn='978-0-375-41398-8';
select * from return_status
where issued_id ='IS134';

CALL update_status('RS140','IS134','Good');

/* T15: Branch Performance Report :Create a query that generates a
performance report for each branch, showing the number of books issued,
the number of books returned, and the total revenue generated from book rentals. */

CREATE TABLE branch_reports 
AS
SELECT b.branch_id, b.manager_id,
	   count(i.issued_id) as no_of_books_issued,
	   count(r.return_id) as no_of_books_return,
	   sum(bk.rental_price) as total_revenue
FROM issued_status i
JOIN employee e
ON i.issued_emp_id = e.emp_id
JOIN branch b
ON e.branch_id = b.branch_id
LEFT JOIN return_status r
ON r.issued_id = i.issued_id
JOIN books bk
ON bk.isbn = i.issued_book_isbn
GROUP BY 1,2;

SELECT * FROM branch_reports;

/*T16: CTAS: Create a Table of Active Members: Use the CREATE TABLE AS (CTAS)
statement to create a new table active_members containing members who have 
issued at least one book in the last 2 months. */
DROP TABLE IF EXISTS active_members;
CREATE TABLE active_members
AS
SELECT i.issued_emp_id, e.emp_name,i.issued_date
FROM issued_status i
JOIN employee e
ON i.issued_emp_id = e. emp_id
WHERE issued_date >= CURRENT_DATE - INTERVAL '2 month';

SELECT * FROM active_members;

/* Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues.
Display the employee name, number of books processed, and their branch. */

SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employee as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2
ORDER BY 3 DESC LIMIT 3;

/* T18: Identify Members Issuing High-Risk Books.Write a query to identify 
members who have issued books with the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books. */

CREATE TABLE damaged_isbn
AS
SELECT i.issued_book_isbn AS dam_isbn
FROM issued_status i
JOIN return_status r
ON r.issued_id=i.issued_id
WHERE r.book_quality='Damaged';

SELECT i.issued_emp_id, e.emp_name,i.issued_id,
       i.issued_book_name,
	   count(i.issued_emp_id) as no_of_timed_issued
FROM issued_status i
JOIN employee e 
ON i.issued_emp_id = e.emp_id
RIGHT JOIN damaged_isbn d
ON i.issued_book_isbn = d.dam_isbn
GROUP BY 1,2,3;

/* T19:Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, 
and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure 
should return an error message indicating that the book is currently not available. */

CREATE OR REPLACE PROCEDURE book_issue(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(5), p_issued_book_isbn VARCHAR(25), p_issued_emp_id VARCHAR(5))
LANGUAGE plpgsql
AS $$

DECLARE
       v_status VARCHAR(10);
BEGIN
        --Checking if book is available
		SELECT status
		       INTO v_status 
	    FROM books
		WHERE isbn = p_issued_book_isbn;

		IF v_status ='yes' THEN 
			INSERT INTO issued_status(issued_id,issued_member_id, issued_date,issued_book_isbn,issued_emp_id)
			VALUES(p_issued_id, p_issued_member_id,CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);
   		    
			UPDATE books
     	    SET status='no'
     		WHERE isbn= p_issued_book_isbn; 
		
			RAISE NOTICE 'Book record added successfully for book isbn : %', p_issued_book_isbn;
		ELSE
			RAISE NOTICE 'The book is currently not available';
		END IF;
END;
$$

CALL book_issue('IS155','C108','978-0-553-29698-2','E104');
CALL book_issue('IS156','C108','978-0-7432-7357-1','E104');
SELECT * FROM books
WHERE isbn='978-0-553-29698-2';


SELECT * FROM books;     
SELECT * FROM branch;     
SELECT * FROM employee;     
SELECT * FROM issued_status;
SELECT * FROM return_status; 
SELECT * FROM members;

/* T20:Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify 
overdue books and calculate fines.Description: Write a CTAS query to create a new table that lists each member 
and the books they have issued but not returned within 30 days. The table should include: The number of overdue books. 
The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. 
The resulting table should show: Member ID Number of overdue books Total fines  */
DROP TABLE IF EXISTS overdue_books;
CREATE TABLE overdue_books
AS
SELECT
	m.member_id,m.member_name,issued_date,
	count(member_id) AS no_of_books_overdue,
	(CURRENT_DATE- issued_date) AS difference_in_days,
	(CURRENT_DATE - issued_date) * 0.5 AS fine
FROM members m
JOIN issued_status i on  m.member_id = i.issued_member_id
JOIN books b ON i.issued_book_isbn = b.isbn
LEFT JOIN return_status r ON i.issued_id = r.issued_id
WHERE r.return_id IS NULL
AND (CURRENT_DATE - issued_date) >0
GROUP BY 1,2,3;

SELECT * FROM overdue_books; 

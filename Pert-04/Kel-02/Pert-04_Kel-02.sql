use bankdb;

-- NO 1 --
CREATE INDEX idx_account
ON accounts(account_number);

select * from accounts where account_number = '4123981372';


-- NO 2 --
CREATE INDEX idx_transaction
ON transactions(transaction_id);

select * from transactions where transaction_id = '0e5ccf7d-0803-476b-8405-23e0b5091c08';

-- NO 3 --
CREATE INDEX comp_idx
ON accounts (customer_id, account_type);
GO

SELECT account_id, account_number, balance 
FROM accounts 
WHERE customer_id = '287bf982-89ce-44b5-bfdd-49407600309a' AND account_type = 'savings';

-- NO 4 --
DECLARE @account_id VARCHAR (255);
DECLARE @balance DECIMAL (10,2);

DECLARE read_cursor CURSOR FOR
SELECT account_id, balance FROM accounts
WHERE balance < 9000;

OPEN read_cursor;
FETCH NEXT FROM read_cursor INTO @account_id, @balance;

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Saldo rendah untuk account_id = ' + @account_id;
	FETCH NEXT FROM read_cursor INTO @account_id, @balance;
END;

CLOSE read_cursor;
DEALLOCATE read_cursor;


-- NO 5 --
DECLARE @first_name VARCHAR (255);
DECLARE @last_name VARCHAR (255);

DECLARE cust_cursor CURSOR FOR
SELECT first_name, last_name FROM customers;

OPEN cust_cursor;

FETCH NEXT FROM cust_cursor INTO @first_name, @last_name;

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Customer: ' + @first_name +' '+ @last_name;
	FETCH NEXT FROM cust_cursor INTO @first_name, @last_name;
END;
CLOSE cust_cursor;
DEALLOCATE cust_cursor;

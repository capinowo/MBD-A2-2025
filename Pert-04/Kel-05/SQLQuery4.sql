-- 1
CREATE NONCLUSTERED INDEX idx_account_number
ON accounts (account_number);

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT 
    name AS index_name,
    type_desc,
    is_primary_key,
    is_unique
FROM sys.indexes
WHERE object_id = OBJECT_ID('accounts');

-- 2
CREATE NONCLUSTERED INDEX idx_transactions_account_id ON transactions (account_id);

EXEC sp_helpindex 'transactions';

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT *
FROM transactions
WHERE account_id = '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- 3
CREATE INDEX idx_accounts_customer_type
ON accounts (customer_id, account_type);

EXEC sp_helpindex 'accounts';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * 
FROM accounts
WHERE customer_id = '5b3fb023-fd43-4cae-8783-ef1c98d11b38'
  AND account_type = 'credit';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- 4
DECLARE @account_id CHAR(36);
DECLARE @balance DECIMAL(18, 2);

DECLARE cur_accounts CURSOR FOR
SELECT account_id, balance
FROM accounts;
OPEN cur_accounts;
FETCH NEXT FROM cur_accounts INTO @account_id, @balance;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @balance < 9000
    BEGIN
        PRINT 'Saldo rendah untuk account_id: ' + @account_id;
    END

    FETCH NEXT FROM cur_accounts INTO @account_id, @balance;
END;

CLOSE cur_accounts;
DEALLOCATE cur_accounts;

-- 5
DECLARE @first_name VARCHAR(50);
DECLARE @last_name VARCHAR(50);
DECLARE @full_name VARCHAR(101);

DECLARE CustomerCursor CURSOR FOR
SELECT first_name, last_name
FROM customers;
OPEN CustomerCursor;
FETCH NEXT FROM CustomerCursor INTO @first_name, @last_name;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @full_name = CONCAT(@first_name, ' ', @last_name);
    PRINT 'Customer: ' + @full_name;

    FETCH NEXT FROM CustomerCursor INTO @first_name, @last_name;
END

CLOSE CustomerCursor;
DEALLOCATE CustomerCursor;

-- 3 VIEW vw_account_card_transaction_detail
CREATE VIEW vw_account_card_transaction_detail AS
SELECT 
    a.account_id,
    a.account_number,
    a.account_type,
    a.balance,
    c.card_number,
    c.card_type,
    t.transaction_id,
    t.transaction_type_id,
    t.amount
FROM accounts a
LEFT JOIN cards c ON a.account_id = c.account_id
LEFT JOIN transactions t ON a.account_id = t.account_id;

SELECT *
FROM vw_account_card_transaction_detail;

-- 4 procedure sp_get_transactions_report
CREATE PROCEDURE sp_get_transactions_report
    @account_id CHAR(36) = NULL,
    @date_from DATE = NULL,
    @date_to DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @date_from IS NULL
        SET @date_from = DATEADD(DAY, -30, GETDATE());
    IF @date_to IS NULL
        SET @date_to = GETDATE();
    SELECT 
        t.transaction_id,
        t.account_id,
        a.account_number,
        t.transaction_type_id,
        t.amount,
        t.transaction_date,
        t.description,
        t.reference_account
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE
        (@account_id IS NULL OR t.account_id = @account_id)
        AND t.transaction_date BETWEEN @date_from AND @date_to
    ORDER BY t.transaction_date DESC;
END;

-- coba 1
EXEC sp_get_transactions_report;
-- coba 2
EXEC sp_get_transactions_report @account_id = '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7';
-- coba 3
EXEC sp_get_transactions_report @date_from = '2024-04-01', @date_to = '2024-04-30';

-- 6 FUNCTION fn_customer_balance_stats
CREATE FUNCTION fn_customer_balance_stats (@customer_id CHAR(36))
RETURNS @result TABLE (
    CustomerId CHAR(36),
    TotalAccounts INT,
    TotalBalance DECIMAL(18,2),
    AverageBalance DECIMAL(18,2)
)
AS
BEGIN
    INSERT INTO @result
    SELECT
        @customer_id AS CustomerId,
        COUNT(*) AS TotalAccounts,
        SUM(balance) AS TotalBalance,
        AVG(balance) AS AverageBalance
    FROM accounts
    WHERE customer_id = @customer_id;

    RETURN;
END;

SELECT * FROM fn_customer_balance_stats('5b3fb023-fd43-4cae-8783-ef1c98d11b38');

-- 8 cursor
DECLARE @account_id CHAR(36);
DECLARE @balance DECIMAL(18, 2);

DECLARE cur_credit_accounts CURSOR FOR
SELECT account_id, balance
FROM accounts
WHERE account_type = 'credit';
OPEN cur_credit_accounts;
FETCH NEXT FROM cur_credit_accounts INTO @account_id, @balance;
WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE accounts
    SET balance = balance * 0.98
    WHERE account_id = @account_id;

    PRINT 'Saldo untuk akun ' + @account_id + ' telah dikurangi 2%';

    FETCH NEXT FROM cur_credit_accounts INTO @account_id, @balance;
END;
CLOSE cur_credit_accounts;
DEALLOCATE cur_credit_accounts;
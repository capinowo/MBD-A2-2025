USE BANKDB;

/* Nomor 3 */
-- Buat View
CREATE VIEW vw_account_card_transaction_detail AS
SELECT 
    a.account_id, a.account_number, a.account_type, a.balance,
    c.card_number, c.card_type,
    t.transaction_id, t.transaction_type_id, t.amount
FROM accounts a
JOIN cards c ON a.account_id = c.account_id
JOIN transactions t ON a.account_id = t.account_id;
-- Lihat Hasil
SELECT * FROM vw_account_card_transaction_detail;


/* Nomor 4 */
CREATE PROCEDURE sp_get_transactions_report
	@account_id CHAR(36) = NULL,
	@date_from DATE = NULL,
	@date_to DATE = NULL
AS
BEGIN

	SET NOCOUNT ON

	IF @date_from IS NULL
        SET @date_from = DATEADD(DAY, 30, GETDATE());

    IF @date_to IS NULL
        SET @date_to = GETDATE();

	SELECT 
        t.transaction_id,
        t.account_id,
        t.transaction_type_id,
        t.amount,
        t.transaction_date,
        t.description,
        t.reference_account
    FROM transactions t
    WHERE
        (@account_id IS NULL OR t.account_id = @account_id)
        AND t.transaction_date BETWEEN @date_from AND @date_to
    ORDER BY t.transaction_date DESC;
END;
-- Pengujian tanpa parameter (memakai default)
EXEC sp_get_transactions_report;
-- Pengujian dengan parameter account_id
EXEC sp_get_transactions_report @account_id = '6edc13ce-6ed2-48a7-b73d-ef6ed8b73e38';
-- Pengujian dengan parameter date_from dan date_to
EXEC sp_get_transactions_report @date_from = '2024-05-01', @date_to = '2025-05-15';
-- Pengujian dengan semua parameter 
EXEC sp_get_transactions_report
    @account_id = '6edc13ce-6ed2-48a7-b73d-ef6ed8b73e38',
    @date_from = '2024-05-01',
    @date_to = '2025-05-15';


/* Nomor 6 */
CREATE FUNCTION dbo.GetCustomerAccountStats (@customer_id CHAR(50))
RETURNS @Stats TABLE (
	CustomerID CHAR (50),
	TotalAccounts INT,
	TotalBalance DECIMAL (18,2),
	AverageBalance DECIMAL (18,2)
)
AS
BEGIN
	INSERT INTO @Stats
	SELECT 
		@customer_id AS CustomerId,
		COUNT(*) AS TotalAccounts,
		SUM(balance) AS TotalBalance,
		AVG(balance) AS AverageBalance
	FROM accounts
	WHERE customer_id = @customer_id;

	RETURN;
END

SELECT * FROM dbo.GetCustomerAccountStats('079cd6ce-04a8-4c55-8c2b-b93189e9050a');


/* Nomor 8 */
DECLARE @account_id CHAR(36);
DECLARE @account_type VARCHAR(50);
DECLARE @balance DECIMAL(18,2);

DECLARE read_account_credit_cursor CURSOR FOR
SELECT account_id, account_type, balance
FROM accounts
WHERE account_type = 'credit';

OPEN read_account_credit_cursor;

FETCH NEXT FROM read_account_credit_cursor INTO @account_id, @account_type, @balance;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @balance > 0
    BEGIN
        DECLARE @new_balance DECIMAL(18,2);
        SET @new_balance = @balance - (@balance * 0.02);

        UPDATE accounts
        SET balance = @new_balance
        WHERE account_id = @account_id;

        PRINT 'Saldo akun ' + @account_id + ' setelah biaya bulanan: ' + CAST(@new_balance AS VARCHAR(20));
    END;

    FETCH NEXT FROM read_account_credit_cursor INTO @account_id, @account_type, @balance;
END;

CLOSE read_account_credit_cursor;
DEALLOCATE read_account_credit_cursor;

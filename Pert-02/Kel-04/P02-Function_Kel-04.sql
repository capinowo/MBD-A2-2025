USE BANKDB;

-- Nomor 1
CREATE FUNCTION fn_GetCustomerFullName (
    @customer_id CHAR(36)
)
RETURNS VARCHAR(101)
AS
BEGIN
    DECLARE @full_name VARCHAR(101);

    SELECT @full_name = CONCAT(first_name, ' ', last_name)
    FROM customers
    WHERE customer_id = @customer_id;

    RETURN @full_name;
END;

SELECT dbo.fn_GetCustomerFullName('079cd6ce-04a8-4c55-8c2b-b93189e9050a') AS nama_lengkap;



-- Nomor 2
CREATE FUNCTION fn_GetTotalBalanceByCustomer (@customer_id CHAR (36))
RETURNS DECIMAL (10, 2)
AS
BEGIN
	DECLARE @total_balance DECIMAL (10, 2);
	SELECT @total_balance = SUM (balance)
	FROM accounts
	WHERE customer_id = @customer_id;

	IF @total_balance IS NULL
	BEGIN
		SET @total_balance = 0;
	END
	RETURN @total_balance;
END;

SELECT dbo.fn_GetTotalBalanceByCustomer('d094e634-9744-478d-b73b-1a73149b198b') AS total_balance;



-- Nomor 3
CREATE FUNCTION fn_GetActiveLoanCount()
RETURNS INT
AS
BEGIN
    DECLARE @count INT

    SELECT @count = COUNT(*)
    FROM loans
    WHERE status = 'active';

    RETURN @count;
END;

SELECT dbo.fn_GetActiveLoanCount() AS total_active_loans;



-- Nomor 4
CREATE FUNCTION fn_GetAccountNetFlow (@account_id CHAR(36))
RETURNS DECIMAL(18, 2)
AS
BEGIN
	DECLARE @total_transaction DECIMAL(18, 2);
	DECLARE @total_masuk DECIMAL(18, 2);
	DECLARE @total_keluar DECIMAL(18, 2);

	SELECT @total_keluar = ISNULL(SUM(amount), 0)
	FROM transactions
	WHERE reference_account = @account_id;

	SELECT @total_masuk = ISNULL(SUM(amount), 0)
	FROM transactions
	WHERE account_id = @account_id AND reference_account IS NOT NULL;

	SET @total_transaction = @total_masuk - @total_keluar;

	RETURN @total_transaction;
END;

SELECT dbo.fn_GetAccountNetFlow('6edc13ce-6ed2-48a7-b73d-ef6ed8b73e38') AS total_transaction;



-- Nomor 5
CREATE FUNCTION fn_GetCustomerFinancialSummary (@customer_id CHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @total_balance DECIMAL(18,2);
    DECLARE @total_loan DECIMAL(18,2);
    DECLARE @total_keuangan DECIMAL(18,2);

    SELECT @total_balance = ISNULL(SUM(balance), 0)
    FROM dbo.accounts
    WHERE customer_id = @customer_id;

    SELECT @total_loan = ISNULL(SUM(loan_amount), 0)
    FROM dbo.loans
    WHERE customer_id = @customer_id;

    SET @total_keuangan = @total_balance + @total_loan;

    RETURN @total_keuangan;
END;

SELECT dbo.fn_GetCustomerFinancialSummary('0bedb8d0-0c5a-48a9-bae1-5b1fbecf4a10') AS Rangkuman_keuangan;
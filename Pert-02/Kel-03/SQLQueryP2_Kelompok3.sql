use bank;

-- soal iv
-- function fn_GetAccountNetFlow yang menerima account_id dan
-- mengembalikan selisih antara total transaksi masuk dan keluar.
--drop function fn_GetAccountNetFlow;
CREATE FUNCTION fn_GetAccountNetFlow(@account_id CHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @totalMasuk DECIMAL(18,2);
    DECLARE @totalKeluar DECIMAL(18,2);

    SELECT @totalMasuk = ISNULL(SUM(amount), 0)
    FROM transactions
    WHERE reference_account = @account_id;

    SELECT @totalKeluar = ISNULL(SUM(amount), 0)
    FROM transactions
    WHERE account_id = @account_id AND reference_account IS NOT NULL;

    RETURN @totalMasuk - @totalKeluar;
END;


SELECT 
    account_id,
    dbo.fn_GetAccountNetFlow('905660c8-d6a7-40e9-9be3-e6711d22efb6') AS NetFlow
FROM accounts;

-- Soal ii
-- ii. function fn_GetTotalBalanceByCustomer yang menerima input 
-- customer_id dan mengembalikan total saldo dari semua akun milik
-- customer tersebut dari tabel accounts.

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

SELECT dbo.fn_GetTotalBalanceByCustomer('ed4658f1-c11e-484a-b761-c911885548c2') AS total_balance;

-- soal v. function fn_GetCustomerFinancialSummary yang menerima customer_id,
-- dan mengembalikan hasil total saldo + total pinjaman.
CREATE FUNCTION fn_GetCustomerFinancialSummary (@customer_id CHAR(36))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @total_balance DECIMAL(18, 2);
    DECLARE @total_loan DECIMAL(18, 2);
    DECLARE @result DECIMAL(18, 2);

    SELECT @total_balance = SUM(balance)
    FROM accounts
    WHERE customer_id = @customer_id;

    SELECT @total_loan = SUM(loan_amount)
    FROM loans
    WHERE customer_id = @customer_id;

    IF @total_balance IS NULL 
SET @total_balance = 0;
    IF @total_loan IS NULL 
SET @total_loan = 0;

    SET @result = @total_balance + @total_loan;
    RETURN @result;
END;

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    dbo.fn_GetCustomerFinancialSummary(c.customer_id) AS total_saldo_dan_total_pinjaman
FROM customers c;


-- soal iii. function fn_GetActiveLoanCount yang menghitung berapa jumlah
-- pinjaman dengan status 'active' pada tabel loans.
CREATE FUNCTION fn_GetActiveLoanCount()
RETURNS INT
AS
BEGIN
    DECLARE @activeLoanCount INT;

    SELECT @activeLoanCount = COUNT(*)
    FROM loans
    WHERE status = 'active';

    RETURN @activeLoanCount;
END;

SELECT dbo.fn_GetActiveLoanCount();


-- soal i. function fn_GetCustomerFullName yang menerima input customer_id dan 
-- mengembalikan nama lengkap customer (gabungan first_name dan last_name).
CREATE FUNCTION fn_GetCustomerFullName (@customer_id VARCHAR(36))
RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE @full_name VARCHAR(255);

    SELECT @full_name = first_name + ' ' + last_name
    FROM customers
    WHERE customer_id = @customer_id;

    RETURN @full_name;
END;

--Aplikasi
SELECT dbo.fn_GetCustomerFullName('f40f3b32-6b03-4f88-896a-949bb777a247') AS FullName;
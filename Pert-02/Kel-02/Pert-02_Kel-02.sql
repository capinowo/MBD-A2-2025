-- NO 1 menerima input customer_id dan mengembalikan nama lengkap customer --
GO
CREATE FUNCTION fn_GetCustomerFullName(@customer_id CHAR(36))
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @namaLengkap VARCHAR(50);
	SELECT @namaLengkap = CONCAT(first_name, CONCAT(' ', last_name))
	FROM customers
	WHERE customer_id = @customer_id;

	IF @namaLengkap IS NULL
	BEGIN
		SET @namaLengkap = '#';
	END
	RETURN @namaLengkap;
END;
GO

SELECT dbo.fn_GetCustomerFullName('287bf982-89ce-44b5-bfdd-49407600309a') AS nama_lengkap;


-- NO 2 menerima input customer_id dan mengembalikan total saldo --
GO
CREATE FUNCTION fn_GetTotalBalanceByCustomer(@customer_id CHAR(36))
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
GO

DROP FUNCTION dbo.fn_GetTotalBalanceByCustomer;

SELECT dbo.fn_GetTotalBalanceByCustomer('287bf982-89ce-44b5-bfdd-49407600309a') AS total_balance;

-- NO 3 yang menghitung berapa jumlah pinjaman dengan status 'active' pada tabel loans --
GO
CREATE FUNCTION fn_GetActiveLoanCount()
RETURNS INTEGER
AS
BEGIN
	DECLARE @totalActive INT;
	SELECT @totalActive = COUNT(*)
	FROM loans
	WHERE status = 'active';

	RETURN @totalActive;
	
END;
GO

SELECT dbo.fn_GetActiveLoanCount() AS total_pinjaman_active;

select * from loans;

select * from transactions where account_id = '6edc13ce-6ed2-48a7-b73d-ef6ed8b73e38';

select * from accounts where account_id = 'd494f351-9ecd-4c50-a7b0-57586ba55764';

select * from transaction_types;

select * from accounts;


-- NO 4 menerima account_id dan mengembalikan selisih antara total transaksi masuk dan keluar --

GO
CREATE FUNCTION fn_GetAccountNetFlow (@account_id CHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @transaksiMasuk DECIMAL(18,2) = 0
    DECLARE @transaksiKeluar DECIMAL(18,2) = 0
    SELECT @transaksiMasuk = ISNULL(SUM(amount), 0)
    FROM transactions t
    JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
    WHERE t.account_id = @account_id AND tt.name = 'Deposit'

    SELECT @transaksiKeluar = ISNULL(SUM(amount), 0)
    FROM transactions t
    JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
    WHERE t.account_id = @account_id AND tt.name = 'Withdrawal'

    RETURN @transaksiMasuk - @transaksiKeluar
END;
GO

SELECT dbo.fn_GetAccountNetFlow('8935d817-99dc-440a-9ef0-27b13711c02d') AS selisih;


-- NO 5 menerima customer_id dan mengembalikan hasil total saldo + total pinjaman --

GO
CREATE FUNCTION fn_GetCustomerFinancialSummary(@customer_id CHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
	DECLARE @totalSaldo DECIMAL(18, 2);
	DECLARE @totalPinjaman DECIMAL(18, 2);
	DECLARE @total DECIMAL(18, 2);
	SELECT @totalSaldo = ISNULL(SUM(balance),0)
	FROM accounts
	WHERE customer_id = @customer_id

	SELECT @totalPinjaman = ISNULL(SUM(loan_amount),0)
	FROM loans
	WHERE customer_id = @customer_id

	RETURN @totalSaldo + @totalPinjaman
END;
GO

DROP FUNCTION fn_GetCustomerFinancialSummary;

SELECT dbo.fn_GetCustomerFinancialSummary('287bf982-89ce-44b5-bfdd-49407600309a') AS Total;

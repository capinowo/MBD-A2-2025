/* KELOMPOK 1 MBD A2
    - Fachryzaidan Akmal (24060122120001)
    - Raja Samuel Tarigan (24060122140157)
*/

/* No. 1
   function fn_GetCustomerFullName yang menerima input customer_id dan mengembalikan nama lengkap customer (gabungan first_name dan last_name). 
*/
CREATE FUNCTION fn_GetCustomerFullName (@customer_id CHAR(36))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @full_name VARCHAR(50);

    SELECT @full_name = CONCAT(first_name, ' ', last_name)
    FROM customers
    WHERE customer_id = @customer_id;

    RETURN @full_name;
END;

SELECT dbo.fn_GetCustomerFullName('079cd6ce-04a8-4c55-8c2b-b93189e9050a') AS full_name;

/* No. 2
   function fn_GetTotalBalanceByCustomer yang menerima input customer_id dan mengembalikan total saldo dari semua akun milik customer tersebut dari tabel accounts. 
*/
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

SELECT dbo.fn_GetTotalBalanceByCustomer('079cd6ce-04a8-4c55-8c2b-b93189e9050a') AS total_balance;

/* No. 3
   function fn_GetActiveLoanCount yang menghitung berapa jumlah pinjaman dengan status 'active' pada tabel loans. 
*/
CREATE FUNCTION fn_GetActiveLoanCount ()
RETURNS INT
AS
BEGIN
    DECLARE @active_loan_count INT;

    SELECT @active_loan_count = COUNT(*)
    FROM loans
    WHERE status = 'active';

    RETURN @active_loan_count;
END;

SELECT dbo.fn_GetActiveLoanCount() AS active_loan_count;

/* No. 4
   function fn_GetAccountNetFlow yang menerima account_id dan mengembalikan selisih antara total transaksi masuk dan keluar. 
*/
CREATE FUNCTION fn_GetAccountNetFlow (@account_id CHAR(36))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @net_flow DECIMAL(10,2);

    SELECT @net_flow = ISNULL(SUM(
        CASE 
            WHEN tt.name IN ('deposit', 'transfer') AND (t.reference_account IS NULL OR t.reference_account = @account_id) THEN t.amount
            WHEN tt.name IN ('withdrawal', 'transfer') AND t.account_id = @account_id THEN -t.amount
            ELSE 0
        END
    ), 0)
    FROM transactions t
    JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
    WHERE t.account_id = @account_id OR t.reference_account = @account_id;

    RETURN @net_flow;
END;

SELECT dbo.fn_GetAccountNetFlow('079cd6ce-04a8-4c55-8c2b-b93189e9050a') AS net_flow;

/* No. 5
   function fn_GetCustomerFinancialSummary yang menerima customer_id dan mengembalikan hasil total saldo + total pinjaman. 
*/
CREATE FUNCTION fn_GetCustomerFinancialSummary (@customer_id CHAR(36))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total_balance DECIMAL(10,2);
    DECLARE @total_loan DECIMAL(10,2);

    SELECT @total_balance = ISNULL(SUM(balance), 0)
    FROM accounts
    WHERE customer_id = @customer_id;

    SELECT @total_loan = ISNULL(SUM(loan_amount), 0)
    FROM loans
    WHERE customer_id = @customer_id AND status = 'active';

    RETURN @total_balance + @total_loan;
END;

SELECT dbo.fn_GetCustomerFinancialSummary('079cd6ce-04a8-4c55-8c2b-b93189e9050a') AS financial_summary;
--1. Fungsi fn_GetCustomerFullName
CREATE FUNCTION fn_GetCustomerFullName (@customer_id CHAR(36))
RETURNS NVARCHAR(101)
AS
BEGIN
    DECLARE @full_name NVARCHAR(101);

    SELECT @full_name = CONCAT(first_name, ' ', last_name)
    FROM customers
    WHERE customer_id = @customer_id;

    RETURN @full_name;
END;

SELECT dbo.fn_GetCustomerFullName('9d78736f-df51-4622-9cb1-c4db88dca2d0') AS FullName;

--2. Fungsi fn_GetTotalBalanceByCustomer
CREATE FUNCTION dbo.fn_GetTotalBalanceByCustomer (@customer_id CHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @total_balance DECIMAL(18,2)

    SELECT @total_balance = SUM(balance) FROM accounts
    WHERE customer_id = @customer_id

    RETURN ISNULL(@total_balance, 0)
END;


SELECT dbo.fn_GetTotalBalanceByCustomer('079cd6ce-04a8-4c55-8c2b-b93189e9050a') AS TotalSaldo;

--3. Fungsi fn_GetActiveLoanCount
CREATE FUNCTION dbo.fn_GetActiveLoanCount()
RETURNS INT
AS
BEGIN
    DECLARE @count INT;
    SELECT @count = COUNT(*)
    FROM loans
    WHERE status = 'active';

    RETURN @count;
END;

SELECT dbo.fn_GetActiveLoanCount() AS ActiveLoanCount;

--4. Fungsi fn_GetAccountNetFlow
CREATE FUNCTION fn_GetAccountNetFlow (@account_id CHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @net_flow DECIMAL(18,2);

    SELECT @net_flow = 
        ISNULL(SUM(CASE WHEN tt.name = 'Deposit' THEN t.amount ELSE 0 END), 0) -
        ISNULL(SUM(CASE WHEN tt.name IN ('Withdrawal', 'Transfer') THEN t.amount ELSE 0 END), 0)
    FROM transactions t
    INNER JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
    WHERE t.account_id = @account_id;

    RETURN @net_flow;
END;

SELECT dbo.fn_GetAccountNetFlow('f9341b55-2686-40af-9e1b-2986672efd92') AS NetFlow;

--5. Fungsi fn_GetCustomerFinancialSummary
CREATE FUNCTION fn_GetCustomerFinancialSummary (@customer_id CHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @total_balance DECIMAL(18,2)
    DECLARE @total_loan DECIMAL(18,2)

    SELECT @total_balance = ISNULL(SUM(balance), 0)
    FROM accounts
    WHERE customer_id = @customer_id

    SELECT @total_loan = ISNULL(SUM(loan_amount), 0)
    FROM loans
    WHERE customer_id = @customer_id AND status = 'active'

    RETURN (@total_balance + @total_loan)
END

SELECT dbo.fn_GetCustomerFinancialSummary('9d78736f-df51-4622-9cb1-c4db88dca2d0') AS FinancialSummary;
USE BANKDB

-- TOPIK 3 FUNCTIONS

CREATE FUNCTION fn_GetTransactionCountByType (@type
VARCHAR(10))
RETURNS INT
AS
BEGIN
-- Kamus Lokal
DECLARE @count INT;
DECLARE @type_id INT;
-- Algoritma
-- Fetch id tipe transaksi
SELECT @type_id = transaction_type_id
FROM transaction_types
WHERE LOWER(name) = LOWER(@type);
-- Kalau type_id null
IF @type_id is null
RETURN 0;
-- Menghitung banyaknya transaksi
SELECT @count = COUNT(*)
FROM transactions
WHERE transaction_type_id = @type_id;
RETURN @count;
END;

SELECT dbo.fn_GetTransactionCountByType('Transfer') AS TotalTransaksi;

--Tugas Functions

SELECT * FROM customers;

-- 1. function fn_GetCustomerFullName yang menerima input customer_id dan mengembalikan nama lengkap customer (gabungan first_name dan last_name).

-- List semua nama customer
SELECT
    c.customer_id,
    dbo.fn_GetCustomerFullName(c.customer_id) AS NamaLengkap
FROM customers c;


CREATE FUNCTION fn_GetCustomerFullName (@customer_id VARCHAR(36))
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @full_name VARCHAR(100);

    SELECT @full_name = first_name + ' ' + last_name
    FROM customers
    WHERE customer_id = @customer_id;

    RETURN @full_name;
END;

SELECT dbo.fn_GetCustomerFullName('00F54BDD-ECDD-4441-99A6-76F01B89D4DC') AS NamaLengkap;

DROP FUNCTION IF EXISTS fn_GetCustomerFullName;


-- 2. function fn_GetTotalBalanceByCustomer yang menerima input  customer_id dan mengembalikan total saldo dari semua akun milik customer tersebut dari tabel accounts.

--List total saldo semua customer
SELECT
    c.customer_id,
    dbo.fn_GetTotalBalanceByCustomer(c.customer_id) AS TotalSaldo
FROM customers c;


CREATE FUNCTION fn_GetTotalBalanceByCustomer (@customer_id VARCHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @total_balance DECIMAL(18,2);

    SELECT @total_balance = SUM(balance)
    FROM accounts
    WHERE customer_id = @customer_id;

    RETURN ISNULL(@total_balance, 0);
END;

SELECT dbo.fn_GetTotalBalanceByCustomer('079cd6ce-04a8-4c55-8c2b-b93189e9050a') AS TotalSaldo;

DROP FUNCTION IF EXISTS fn_GetTotalBalanceByCustomer;


-- 3. function fn_GetActiveLoanCount yang menghitung berapa jumlah pinjaman dengan status 'active' pada tabel loans.

--List customer pinjaman aktif
SELECT
    c.customer_id,
    c.first_name + ' ' + c.last_name AS NamaCustomer,
    l.loan_id,
    l.loan_amount,
    l.status
FROM customers c
JOIN loans l ON c.customer_id = l.customer_id
WHERE l.status = 'active';


CREATE FUNCTION fn_GetActiveLoanCount()
RETURNS INT
AS
BEGIN
    DECLARE @active_loans INT;

    SELECT @active_loans = COUNT(*)
    FROM loans
    WHERE status = 'active';

    RETURN @active_loans;
END;

SELECT dbo.fn_GetActiveLoanCount() AS JumlahPinjamanAktif;

DROP FUNCTION IF EXISTS fn_GetActiveLoanCount;


-- 4. function fn_GetAccountNetFlow yang menerima account_id dan mengembalikan selisih antara total transaksi masuk dan keluar.

--Daftar Net Transaksi Semua Akun
SELECT 
	c.first_name + ' ' + c.last_name AS NamaCustomer,
    a.account_id,
    a.account_number,
    a.customer_id,
    dbo.fn_GetAccountNetFlow(a.account_id) AS NetTransaksi
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id;


CREATE FUNCTION fn_GetAccountNetFlow (@account_id VARCHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @inflow DECIMAL(18,2);
    DECLARE @outflow DECIMAL(18,2);

    -- Total transaksi masuk
    SELECT @inflow = SUM(amount)
    FROM transactions
    WHERE account_id = @account_id AND transaction_type_id = 1;

    -- Total transaksi keluar
    SELECT @outflow = SUM(amount)
    FROM transactions
    WHERE account_id = @account_id AND transaction_type_id = 2;

    RETURN ISNULL(@inflow, 0) - ISNULL(@outflow, 0);
END;

SELECT dbo.fn_GetAccountNetFlow('07a36a4b-7943-4634-b17a-7c7eb4407cd3') AS NetTransaksi;

DROP FUNCTION IF EXISTS fn_GetAccountNetFlow;


-- 5. function fn_GetCustomerFinancialSummary yang menerima customer_id, dan mengembalikan hasil total saldo + total pinjaman.

--Daftar Ringkasan Semua Customer
SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS NamaCustomer,
    dbo.fn_GetCustomerFinancialSummary(c.customer_id) AS RingkasanKeuangan
FROM customers c;


CREATE FUNCTION fn_GetCustomerFinancialSummary (@customer_id VARCHAR(36))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @total_balance DECIMAL(18,2);
    DECLARE @total_loan DECIMAL(18,2);

    -- Ambil total saldo dari semua akun customer
    SELECT @total_balance = SUM(balance)
    FROM accounts
    WHERE customer_id = @customer_id;

    -- Ambil total jumlah pinjaman customer
    SELECT @total_loan = SUM(loan_amount)
    FROM loans
    WHERE customer_id = @customer_id;

    RETURN ISNULL(@total_balance, 0) + ISNULL(@total_loan, 0);
END;

SELECT dbo.fn_GetCustomerFinancialSummary('14f35ff7-5574-4e12-ad89-7e7704a02e62') AS RingkasanKeuangan;

DROP FUNCTION IF EXISTS fn_GetCustomerFinancialSummary;
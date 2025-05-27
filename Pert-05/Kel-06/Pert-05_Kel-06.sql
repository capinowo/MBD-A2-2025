USE BANKDB

-- Menampilkan seluruh isi tabel transactions
SELECT * FROM transactions;

-- Menampilkan jumlah record (baris) sebagai indikator data sudah terisi atau belum
SELECT COUNT(*) AS Total_Transaksi FROM transactions;



-- iii. Detail Gabungan Akun, Kartu, dan Transaksi
-- Drop view jika sudah ada
IF OBJECT_ID('vw_account_card_transaction_detail', 'V') IS NOT NULL 
    DROP VIEW vw_account_card_transaction_detail;

-- Insert ke transaction_types (jika belum ada)
IF NOT EXISTS (SELECT 1 FROM transaction_types WHERE transaction_type_id IN (1, 2, 3))
BEGIN
    INSERT INTO transaction_types (transaction_type_id, name) VALUES
    (1, 'deposit'),
    (2, 'transfer'),
    (3, 'withdrawal');
END

-- Insert 1 dummy customer (karena account_id butuh relasi customer_id)
DECLARE @customer_id CHAR(36) = NEWID();

INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address)
VALUES (
    @customer_id, 'Dummy', 'User', 'dummy@email.com', '081234567890', '123 Main Street');

-- Insert dummy account
DECLARE @account_id CHAR(36) = NEWID();
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
VALUES (
    @account_id, @customer_id, '1234567890', 'savings', 10000.00
);

-- Insert dummy card
DECLARE @card_id CHAR(36) = NEWID();
INSERT INTO cards (card_id, account_id, card_number, card_type, expiration_date)
VALUES (
    @card_id, @account_id, '4111222233334444', 'debit', '2026-12-31'
);

-- Insert dummy transaction
DECLARE @transaction_id CHAR(36) = NEWID();
INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account)
VALUES (
    @transaction_id, @account_id, 1, 7500.00, GETDATE(), 'Setoran awal', NULL
);

-- Buat ulang view
CREATE VIEW vw_account_card_transaction_detail AS
SELECT 
    a.account_id AS [Account Id],
    a.account_number AS [Account Number],
    a.account_type AS [Account Type],
    a.balance AS [Balance],
    c.card_number AS [Card Number],
    c.card_type AS [Card Type],
    t.transaction_id AS [Transaction Id],
    tt.name AS [Transaction Type],
    t.amount AS [Amount]
FROM accounts a
JOIN cards c ON a.account_id = c.account_id
JOIN transactions t ON a.account_id = t.account_id
JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id;

-- Tampilkan hasil view
SELECT * FROM vw_account_card_transaction_detail;



-- iv. Laporan Transaksi Dinamis
IF OBJECT_ID('sp_get_transactions_report', 'P') IS NOT NULL 
    DROP PROCEDURE sp_get_transactions_report;
GO

CREATE PROCEDURE sp_get_transactions_report
    @account_id CHAR(36) = NULL,
    @date_from DATE = NULL,
    @date_to DATE = NULL
AS
BEGIN
    -- Default: 30 hari terakhir jika tidak diisi
    IF @date_from IS NULL SET @date_from = DATEADD(DAY, -30, GETDATE());
    IF @date_to IS NULL SET @date_to = GETDATE();

    -- Tampilkan transaksi
    SELECT *
    FROM transactions
    WHERE (@account_id IS NULL OR account_id = @account_id)
      AND transaction_date BETWEEN @date_from AND @date_to;
END;
GO

-- Contoh pemanggilan: Semua transaksi 30 hari terakhir
EXEC sp_get_transactions_report;



-- vi. Statistik Akun dan Saldo Customer
IF OBJECT_ID('fn_customer_account_stats', 'IF') IS NOT NULL 
    DROP FUNCTION fn_customer_account_stats;
GO

CREATE FUNCTION fn_customer_account_stats (@customer_id CHAR(36))
RETURNS TABLE
AS
RETURN (
    SELECT 
        @customer_id AS customer_id,
        COUNT(*) AS total_accounts,
        SUM(balance) AS total_balance,
        AVG(balance) AS average_balance
    FROM accounts
    WHERE customer_id = @customer_id
);
GO

-- Contoh pemanggilan (gunakan ID yang valid)
SELECT TOP 1 customer_id FROM customers;

SELECT * 
FROM fn_customer_account_stats('079cd6ce-04a8-4c55-8c2b-b93189e9050a');



-- viii. Potongan 2% Saldo Akun Kredit (dengan pengecekan sebelum dan sesudah)
-- Akun credit dummy
DECLARE @customer_id CHAR(36) = (SELECT TOP 1 customer_id FROM customers);
IF @customer_id IS NULL
BEGIN
    SET @customer_id = NEWID();
    INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address)
    VALUES (@customer_id, 'Credit', 'User', 'credit@example.com', '089999999999', 'Jl. Kredit No. 1');
END

-- Tambahkan akun kredit (jika belum ada)
DECLARE @credit_account_id CHAR(36) = NEWID();
IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_type = 'credit')
BEGIN
    INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
    VALUES (
        @credit_account_id, @customer_id, '9999999999', 'credit', 200000.00
    );
END

-- Simpan kondisi sebelum pemotongan
IF OBJECT_ID('tempdb..#before_cut') IS NOT NULL DROP TABLE #before_cut;
SELECT account_id, balance AS balance_before
INTO #before_cut
FROM accounts
WHERE account_type = 'credit';

-- Tampilkan sebelum potong
SELECT * FROM #before_cut;

-- Jalankan cursor untuk potong 2%
DECLARE credit_cursor CURSOR FOR
    SELECT account_id, balance FROM accounts WHERE account_type = 'credit';

DECLARE @account_id CHAR(36), @balance DECIMAL(18,2);

OPEN credit_cursor;
FETCH NEXT FROM credit_cursor INTO @account_id, @balance;

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE accounts
    SET balance = balance - (@balance * 0.02)
    WHERE account_id = @account_id;

    FETCH NEXT FROM credit_cursor INTO @account_id, @balance;
END;

CLOSE credit_cursor;
DEALLOCATE credit_cursor;

-- Tampilkan sesudah potong
SELECT 
    a.account_id,
    b.balance_before,
    a.balance AS balance_after,
    (b.balance_before - a.balance) AS amount_deducted
FROM accounts a
JOIN #before_cut b ON a.account_id = b.account_id
WHERE a.account_type = 'credit';


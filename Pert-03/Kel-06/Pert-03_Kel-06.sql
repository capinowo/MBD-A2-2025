USE BANKDB;
GO

-- ===========================================
-- SOAL 1: TRIGGER VALIDASI SALDO CUKUP (tr_UpdateAccountBalance_BeforeTransaction)
-- ===========================================

-- RESET DATA AWAL (Hapus semua data terkait)
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO

-- INISIALISASI DATA AWAL UNTUK TESTING (SOAL 1-4)
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address) VALUES
('CUST001', 'Andi', 'Wijaya', 'andi@mail.com', '081234567890', 'Jakarta'),
('CUST002', 'Budi', 'Santoso', 'budi@mail.com', '081234567891', 'Bandung');
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance) VALUES
('ACC001', 'CUST001', '001', 'savings', 500000),
('ACC002', 'CUST002', '002', 'savings', 150000);
INSERT INTO transaction_types (transaction_type_id, name) VALUES
(1, 'Deposit'), (2, 'Transfer'), (3, 'Withdrawal');
GO

-- TAMPILKAN DATA SEBELUM TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- BUAT TRIGGER: Validasi saldo cukup & update saldo untuk withdrawal/transfer
CREATE OR ALTER TRIGGER tr_UpdateAccountBalance_BeforeTransaction
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    -- Validasi saldo cukup untuk withdrawal/transfer
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.transaction_type_id IN (2,3) AND a.balance < i.amount
    )
    BEGIN
        RAISERROR('Saldo tidak cukup.', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END

    -- Update saldo akun
    UPDATE a
    SET a.balance = 
        CASE 
            WHEN i.transaction_type_id = 1 THEN a.balance + i.amount -- Deposit
            WHEN i.transaction_type_id IN (2,3) THEN a.balance - i.amount -- Transfer/Withdrawal
            ELSE a.balance
        END
    FROM accounts a
    JOIN inserted i ON a.account_id = i.account_id;

    -- Insert transaksi
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    SELECT account_id, transaction_type_id, amount, transaction_date, description, reference_account FROM inserted;
END
GO

-- TESTING TRIGGER
-- Gagal: saldo tidak cukup
BEGIN TRY
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    VALUES ('ACC001', 3, 600000, GETDATE(), 'Test gagal', NULL);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH

-- Berhasil: saldo cukup (withdrawal)
BEGIN TRY
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    VALUES ('ACC002', 3, 100000, GETDATE(), 'Test berhasil', NULL);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH

-- Berhasil: deposit
BEGIN TRY
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    VALUES ('ACC001', 1, 200000, GETDATE(), 'Test deposit', NULL);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH

-- TAMPILKAN DATA SESUDAH TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- HAPUS TRIGGER & RESET DATA (untuk soal berikutnya)
DROP TRIGGER tr_UpdateAccountBalance_BeforeTransaction;
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO



-- ===========================================
-- SOAL 2: TRIGGER AUTO DEPOSIT SETELAH TRANSFER (tr_Deposit_AfterTransaction)
-- ===========================================

-- RESET DATA AWAL
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO

-- INISIALISASI DATA AWAL
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address) VALUES
('CUST001', 'Andi', 'Wijaya', 'andi@mail.com', '081234567890', 'Jakarta'),
('CUST002', 'Budi', 'Santoso', 'budi@mail.com', '081234567891', 'Bandung');
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance) VALUES
('ACC001', 'CUST001', '001', 'savings', 500000),
('ACC002', 'CUST002', '002', 'savings', 150000);
INSERT INTO transaction_types (transaction_type_id, name) VALUES
(1, 'Deposit'), (2, 'Transfer'), (3, 'Withdrawal');
GO

-- TAMPILKAN DATA SEBELUM TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- BUAT TRIGGER: Auto deposit ke akun tujuan setelah transfer
CREATE OR ALTER TRIGGER tr_Deposit_AfterTransaction
ON transactions
AFTER INSERT
AS
BEGIN
    -- Insert transaksi deposit otomatis ke akun tujuan transfer
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    SELECT
        i.reference_account, 1, i.amount, GETDATE(), 'Auto deposit from transfer', i.account_id
    FROM inserted i
    WHERE i.transaction_type_id = 2 AND i.reference_account IS NOT NULL;

    -- Update saldo akun tujuan transfer
    UPDATE a
    SET a.balance = a.balance + i.amount
    FROM accounts a
    JOIN inserted i ON a.account_id = i.reference_account
    WHERE i.transaction_type_id = 2 AND i.reference_account IS NOT NULL;
END
GO

-- TESTING TRIGGER
-- Transfer (harus auto deposit ke tujuan)
INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
VALUES ('ACC001', 2, 50000, GETDATE(), 'Test transfer', 'ACC002');

-- TAMPILKAN DATA SESUDAH TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- HAPUS TRIGGER & RESET DATA
DROP TRIGGER tr_Deposit_AfterTransaction;
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO



-- ===========================================
-- SOAL 3: TRIGGER MAKSIMAL 3 AKUN PER CUSTOMER (tr_LimitAccountsPerCustomer)
-- ===========================================

-- RESET DATA AWAL
DELETE FROM accounts; DELETE FROM customers;
GO

-- INISIALISASI DATA AWAL
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address) VALUES
('CUST001', 'Andi', 'Wijaya', 'andi@mail.com', '081234567890', 'Jakarta');
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance) VALUES
('ACC001', 'CUST001', '001', 'savings', 500000),
('ACC002', 'CUST001', '002', 'current', 200000),
('ACC003', 'CUST001', '003', 'credit', 300000);
GO

-- TAMPILKAN DATA SEBELUM TESTING
SELECT * FROM accounts;

-- BUAT TRIGGER: Maksimal 3 akun per customer
CREATE OR ALTER TRIGGER tr_LimitAccountsPerCustomer
ON accounts
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN (SELECT customer_id, COUNT(*) AS cnt FROM accounts GROUP BY customer_id) a
        ON i.customer_id = a.customer_id
        WHERE a.cnt >= 3
    )
    BEGIN
        RAISERROR('Customer sudah memiliki 3 akun.', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END
    INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
    SELECT account_id, customer_id, account_number, account_type, balance FROM inserted;
END
GO

-- TESTING TRIGGER
-- Gagal: akun ke-4 customer sama
BEGIN TRY
    INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
    VALUES ('ACC004', 'CUST001', '004', 'savings', 100000);
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH

-- Berhasil: akun pertama customer baru
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address) VALUES
('CUST002', 'Budi', 'Santoso', 'budi@mail.com', '081234567891', 'Bandung');
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
VALUES ('ACC005', 'CUST002', '005', 'savings', 150000);

-- TAMPILKAN DATA SESUDAH TESTING
SELECT * FROM accounts;

-- HAPUS TRIGGER & RESET DATA
DROP TRIGGER tr_LimitAccountsPerCustomer;
DELETE FROM accounts; DELETE FROM customers;
GO



-- ===========================================
-- SOAL 4: TRIGGER VALIDASI AKUN TUJUAN TRANSFER (tr_BlockInvalidReferenceAccount)
-- ===========================================

-- RESET DATA AWAL
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO

-- INISIALISASI DATA AWAL
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address) VALUES
('CUST001', 'Andi', 'Wijaya', 'andi@mail.com', '081234567890', 'Jakarta'),
('CUST002', 'Budi', 'Santoso', 'budi@mail.com', '081234567891', 'Bandung');
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance) VALUES
('ACC001', 'CUST001', '001', 'savings', 500000),
('ACC002', 'CUST002', '002', 'savings', 150000);
INSERT INTO transaction_types (transaction_type_id, name) VALUES
(1, 'Deposit'), (2, 'Transfer'), (3, 'Withdrawal');
GO

-- TAMPILKAN DATA SEBELUM TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- BUAT TRIGGER: Validasi akun tujuan transfer
CREATE OR ALTER TRIGGER tr_BlockInvalidReferenceAccount
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE i.transaction_type_id = 2 AND
        (i.reference_account IS NULL OR NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = i.reference_account))
    )
    BEGIN
        RAISERROR('Akun tujuan transfer tidak valid.', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    SELECT account_id, transaction_type_id, amount, transaction_date, description, reference_account FROM inserted;
END
GO

-- TESTING TRIGGER
-- Gagal: akun tujuan tidak valid
BEGIN TRY
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    VALUES ('ACC001', 2, 50000, GETDATE(), 'Test gagal', 'ACC999');
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH
-- Berhasil: akun tujuan valid
INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
VALUES ('ACC001', 2, 50000, GETDATE(), 'Test berhasil', 'ACC002');

-- TAMPILKAN DATA SESUDAH TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- HAPUS TRIGGER & RESET DATA
DROP TRIGGER tr_BlockInvalidReferenceAccount;
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO



-- ===========================================
-- SOAL 5: TRIGGER SALDO MINIMAL 100.000 (tr_EnsureMinimumBalance)
-- ===========================================

-- RESET DATA AWAL
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO

-- INISIALISASI DATA AWAL
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address) VALUES
('CUST001', 'Andi', 'Wijaya', 'andi@mail.com', '081234567890', 'Jakarta'),
('CUST002', 'Budi', 'Santoso', 'budi@mail.com', '081234567891', 'Bandung');
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance) VALUES
('ACC001', 'CUST001', '001', 'savings', 500000),
('ACC002', 'CUST002', '002', 'savings', 150000);
INSERT INTO transaction_types (transaction_type_id, name) VALUES
(1, 'Deposit'), (2, 'Transfer'), (3, 'Withdrawal');
GO
-- TAMPILKAN DATA SEBELUM TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- BUAT TRIGGER: Saldo minimal 100.000 setelah transaksi
CREATE OR ALTER TRIGGER tr_EnsureMinimumBalance
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN accounts a ON i.account_id = a.account_id
        WHERE i.transaction_type_id IN (2,3) AND (a.balance - i.amount) < 100000
    )
    BEGIN
        RAISERROR('Saldo setelah transaksi harus minimal 100.000.', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    SELECT account_id, transaction_type_id, amount, transaction_date, description, reference_account FROM inserted;
END
GO

-- TESTING TRIGGER
-- Gagal: saldo akhir < 100.000
BEGIN TRY
    INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    VALUES ('ACC001', 3, 150000, GETDATE(), 'Test gagal', NULL);
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH
-- Berhasil: saldo akhir cukup
INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description, reference_account)
VALUES ('ACC001', 3, 50000, GETDATE(), 'Test berhasil', NULL);

-- TAMPILKAN DATA SESUDAH TESTING
SELECT * FROM accounts;
SELECT * FROM transactions;

-- HAPUS TRIGGER & RESET DATA
DROP TRIGGER tr_EnsureMinimumBalance;
DELETE FROM transactions; DELETE FROM accounts; DELETE FROM customers; DELETE FROM transaction_types;
GO
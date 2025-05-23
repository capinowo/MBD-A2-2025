/* KELOMPOK 1 MBD A2
    - Fachryzaidan Akmal (24060122120001)
    - Raja Samuel Tarigan (24060122140157)
*/

-- VIEWS

/* 1. view v_customer_all menampilkan semua isi tabel customers. */
CREATE VIEW v_customer_all AS
SELECT *
FROM customers;

/*2. view v_deposit_transaction menampilkan semua transaksi deposit.*/
CREATE VIEW v_deposit_transaction AS
SELECT t.*
FROM transactions t
JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
WHERE tt.name = 'deposit';

/*3. view v_transfer_transaction menampilkan semua transaksi transfer.*/
CREATE VIEW v_transfer_transaction AS
SELECT t.*
FROM transactions t
JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
WHERE tt.name = 'transfer';


-- PROCEDURE

/* 1. Procedure sp_CreateCustomer untuk menambahkan customer baru ke
dalam tabel customers: input first_name, last_name, email, phone_number, address.*/
CREATE PROCEDURE sp_CreateCustomer
    @first_name VARCHAR(50),
    @last_name VARCHAR(50),
    @email VARCHAR(50),
    @phone_number VARCHAR(20),
    @address VARCHAR(255)
AS
BEGIN
    INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address)
    VALUES (NEWID(), @first_name, @last_name, @email, @phone_number, @address);
END;

/* 2. Procedure sp_CreateAccount untuk membuat akun baru untuk customer
yang sudah ada: input customer_id, account_number, account_type, balance.*/
CREATE PROCEDURE sp_CreateAccount
    @customer_id CHAR(36),
    @account_number CHAR(10),
    @account_type VARCHAR(50),
    @balance DECIMAL(18,2)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM customers WHERE customer_id = @customer_id)
    BEGIN
        INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
        VALUES (NEWID(), @customer_id, @account_number, @account_type, @balance);
    END
    ELSE
    BEGIN
        RAISERROR('Customer ID tidak ditemukan.', 16, 1);
    END
END;

/* 3. Procedure sp_MakeTransaction untuk menambahkan transaksi baru: input account_id,
transaction_type_id, amount, description, reference_account (opsional).*/
CREATE PROCEDURE sp_MakeTransaction
    @account_id CHAR(36),
    @transaction_type_id INT,
    @amount DECIMAL(18,2),
    @description VARCHAR(50),
    @reference_account CHAR(36) = NULL
AS
BEGIN
    DECLARE @transaction_type VARCHAR(50);
    DECLARE @balance DECIMAL(18,2);

    SELECT @transaction_type = name FROM transaction_types WHERE transaction_type_id = @transaction_type_id;

    SELECT @balance = balance FROM accounts WHERE account_id = @account_id;

    IF @transaction_type IS NULL
    BEGIN
        RAISERROR('Jenis transaksi tidak valid.', 16, 1);
        RETURN;
    END

    IF @transaction_type = 'transfer' AND @amount > @balance
    BEGIN
        RAISERROR('Saldo tidak mencukupi untuk transfer.', 16, 1);
        RETURN;
    END

    IF @transaction_type = 'deposit'
    BEGIN
        UPDATE accounts SET balance = balance + @amount WHERE account_id = @account_id;
    END
    ELSE IF @transaction_type = 'withdrawal' OR @transaction_type = 'transfer'
    BEGIN
        UPDATE accounts SET balance = balance - @amount WHERE account_id = @account_id;
    END

    INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, description, reference_account)
    VALUES (NEWID(), @account_id, @transaction_type_id, @amount, @description, @reference_account);

    IF @transaction_type = 'transfer' AND @reference_account IS NOT NULL
    BEGIN
        UPDATE accounts SET balance = balance + @amount WHERE account_id = @reference_account;

        INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, description, reference_account)
        VALUES (NEWID(), @reference_account, @transaction_type_id, @amount, 'Transfer Masuk', @account_id);
    END
END;

/* 4. Procedure sp_GetCustomerSummary untuk menampilkan ringkasan data customer berdasarkan customer_id: Nama lengkap customer, 
Jumlah akun yang dimiliki, Jumlah total saldo semua akun, Jumlah pinjaman aktif, Total pinjaman amount aktif*/
CREATE PROCEDURE sp_GetCustomerSummary
    @customer_id CHAR(36)
AS
BEGIN
    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        COUNT(DISTINCT a.account_id) AS total_accounts,
        ISNULL(SUM(a.balance), 0) AS total_balance,
        COUNT(DISTINCT l.loan_id) AS active_loans,
        ISNULL(SUM(l.loan_amount), 0) AS total_active_loan_amount
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id AND l.status = 'active'
    WHERE c.customer_id = @customer_id
    GROUP BY c.first_name, c.last_name;
END;
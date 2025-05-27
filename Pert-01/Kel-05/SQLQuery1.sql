-- View v_customer_all
CREATE VIEW v_customer_all
AS
SELECT *
FROM customers;

SELECT * FROM v_customer_all;

-- View v_deposit_transaction
CREATE VIEW v_deposit_transaction
AS
SELECT 
    t.transaction_id,
    t.account_id,
    a.account_number,
    t.amount AS deposit_amount,
    t.transaction_date,
    t.description,
    c.first_name + ' ' + c.last_name AS customer_name
FROM 
    transactions t
INNER JOIN 
    accounts a ON t.account_id = a.account_id
INNER JOIN 
    customers c ON a.customer_id = c.customer_id
WHERE 
    t.transaction_type_id = 1;

SELECT * FROM v_deposit_transaction;

-- View v_transfer_transaction
CREATE VIEW v_transfer_transaction AS
SELECT 
    t.transaction_id,
    t.account_id AS sender_account_id,
    a.account_number AS sender_account_number,
    t.reference_account AS receiver_account_id,
    ra.account_number AS receiver_account_number,
    t.amount,
    t.transaction_date,
    t.description
FROM transactions t
JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN accounts a ON t.account_id = a.account_id
LEFT JOIN accounts ra ON t.reference_account = ra.account_id
WHERE tt.name = 'Transfer';

SELECT * FROM v_transfer_transaction;

-- Procedure sp_CreateCustomer
CREATE PROCEDURE sp_CreateCustomer
    @first_name     VARCHAR(50),
    @last_name      VARCHAR(50),
    @email          VARCHAR(50),
    @phone_number   VARCHAR(20),
    @address        VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO customers (
        customer_id, first_name, last_name, email, phone_number, address
    )
    VALUES (
        NEWID(), @first_name, @last_name, @email, @phone_number, @address
    );
END;

EXEC sp_CreateCustomer
    @first_name = 'Jane',
    @last_name = 'Doe',
    @email = 'jane.doe@example.com',
    @phone_number = '081234567890',
    @address = 'Jl. Mawar No. 123, Jakarta';

SELECT * FROM customers WHERE first_name = 'Jane';

-- Procedure sp_CreateAccount
CREATE PROCEDURE sp_CreateAccount
    @customer_id     CHAR(36),
    @account_number  VARCHAR(20),
    @account_type    VARCHAR(20),
    @balance         DECIMAL(15, 2)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM customers WHERE customer_id = @customer_id)
    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_type, balance)
        VALUES (@customer_id, @account_number, @account_type, @balance);
    END
    ELSE
    BEGIN
        RAISERROR('Customer ID tidak ditemukan.', 16, 1);
    END
END;

EXEC sp_CreateAccount
    @customer_id = '07c64dce-04a8-4c55-8c2b-b93189e9050a',
    @account_number = 'ACC123456',
    @account_type = 'Savings',
    @balance = 1500000.00;

-- Procedure sp_MakeTransaction
CREATE OR ALTER PROCEDURE sp_MakeTransaction
    @account_id CHAR(36),
    @transaction_type_id INT,
    @amount DECIMAL(18,2),
    @description VARCHAR(MAX),
    @reference_account CHAR(36) = NULL -- opsional
    -- parameter input prosedur
AS
BEGIN
    SET NOCOUNT ON;
    -- mematikan respon balik sistem basis data

    DECLARE @current_balance DECIMAL(18,2);
    -- variabel sementara tabungan saat ini

    -- Validasi: Pastikan account_id ada
    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = @account_id)
    BEGIN
        RAISERROR('Account ID tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Ambil saldo sekarang
    SELECT @current_balance = balance FROM accounts WHERE account_id = @account_id;

    -- Cek: kalau ini transaksi transfer
    IF (@transaction_type_id = 2) 
    BEGIN
        -- Kalau saldo kurang
        IF @current_balance < @amount
        BEGIN
            RAISERROR('Saldo tidak cukup untuk transfer.', 16, 1);
            RETURN;
        END

        -- Kurangi saldo account asal
        UPDATE accounts
        SET balance = balance - @amount
        WHERE account_id = @account_id;

        -- Tambah saldo ke rekening tujuan jika reference_account tidak NULL
        IF @reference_account IS NOT NULL
        BEGIN
            -- Validasi reference_account ada
            IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = @reference_account)
            BEGIN
                RAISERROR('Reference Account ID tidak ditemukan.', 16, 1);
                RETURN;
            END

            UPDATE accounts
            SET balance = balance + @amount
            WHERE account_id = @reference_account;
        END
    END

    -- Insert transaksi
    INSERT INTO transactions (account_id, transaction_type_id, amount, description, reference_account)
    VALUES (@account_id, @transaction_type_id, @amount, @description, @reference_account);
END

-- Transfer berhasil: dari A ke B sebesar 20.000
EXEC sp_MakeTransaction
    @account_id = 'accid-A',
    @transaction_type_id = 2, -- Transfer
    @amount = 20000,
    @description = 'Transfer ke B',
    @reference_account = 'accid-B';

-- Transfer gagal: saldo kurang
EXEC sp_MakeTransaction
    @account_id = 'accid-A',
    @transaction_type_id = 2,
    @amount = 999999,
    @description = 'Transfer besar gagal',
    @reference_account = 'accid-B';

-- Transfer gagal: reference_account tidak ada
EXEC sp_MakeTransaction
    @account_id = 'accid-A',
    @transaction_type_id = 2,
    @amount = 10000,
    @description = 'Transfer ke rekening palsu',
    @reference_account = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX';

-- Setoran langsung (bukan transfer, transaction_type_id misalnya 1 = deposit)
EXEC sp_MakeTransaction
    @account_id = 'accid-B',
    @transaction_type_id = 1,
    @amount = 5000,
    @description = 'Setor tunai',
    @reference_account = NULL;

-- Procedure sp_GetCustomerSummary
CREATE PROCEDURE sp_GetCustomerSummary
    @customer_id CHAR(36)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validasi: pastikan customer_id ada
    IF NOT EXISTS (
        SELECT 1 FROM customers WHERE customer_id = @customer_id
    )
    BEGIN
        RAISERROR('Customer ID tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Ringkasan customer
    SELECT
        CONCAT(first_name, ' ', last_name) AS full_name,
        (SELECT COUNT(*) FROM accounts WHERE customer_id = c.customer_id) AS total_accounts,
        (SELECT ISNULL(SUM(balance), 0) FROM accounts WHERE customer_id = c.customer_id) AS total_balance,
        (SELECT COUNT(*) FROM loans WHERE customer_id = c.customer_id AND status = 'active') AS active_loans,
        (SELECT ISNULL(SUM(loan_amount), 0) FROM loans WHERE customer_id = c.customer_id AND status = 'active') AS total_active_loan_amount
    FROM customers c
    WHERE c.customer_id = @customer_id;
END;

EXEC sp_GetCustomerSummary
    @customer_id = '1f2aa50e-b682-43da-b36e-f33d041691dc';

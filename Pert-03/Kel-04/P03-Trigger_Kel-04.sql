use BANKDB;

--NOMOR 1
CREATE TRIGGER tr_UpdtaeAccountBalance_BeforeTransaction
ON transactions
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @account_id CHAR(36), @amount DECIMAL(10,2), @total_saldo  DECIMAL(10,2);

	SELECT @account_id = account_id, @amount = amount
	FROM inserted;

	SELECT @total_saldo = balance
	FROM accounts
	WHERE account_id = @account_id;

	IF @total_saldo < @amount
	BEGIN
		RAISERROR('Saldo tidak mencukupi', 10, 1)
		ROLLBACK TRANSACTION;
		RETURN;
	END

	INSERT INTO transactions(account_id, transaction_type_id, amount, transaction_date, description, reference_account)
	SELECT account_id, transaction_type_id, amount, transaction_date, description, reference_account
	FROM inserted;

	UPDATE accounts
	SET balance = @total_saldo - @amount
	WHERE account_id = @account_id;
END

INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description)
VALUES ('6edc13ce-6ed2-48a7-b73d-ef6ed8b73e38', 1, 10000.00, GETDATE(), 'Penarikan ATM');

--NOMOR 2
CREATE TRIGGER tr_Deposit_AfterTransaction
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO transactions (account_id, transaction_type_id, amount, description)
    SELECT a.account_id, 1, i.amount, 'Penerimaan transfer dari akun lain'
    FROM inserted i
    JOIN accounts a ON a.account_number = i.reference_account
    WHERE i.transaction_type_id = 3;
END

-- Tambah dua akun untuk pengujian
INSERT INTO customers (first_name, last_name, email, phone_number, address)
VALUES ('Akmal', 'FA', 'akmal@gmail.com', '08991234567', 'Bandung');

DECLARE @cust_id CHAR(36) = (SELECT TOP 1 customer_id FROM customers WHERE first_name = 'Akmal');

-- Akun asal (1111111111)
INSERT INTO accounts (customer_id, account_number, account_type, balance)
VALUES (@cust_id, '1111111111', 'savings', 200000.00);

-- Akun tujuan (2222222222)
INSERT INTO accounts (customer_id, account_number, account_type, balance)
VALUES (@cust_id, '2222222222', 'savings', 100000.00);

-- Lakukan transaksi transfer
DECLARE @acc_id CHAR(36) = (
    SELECT account_id FROM accounts WHERE account_number = '1111111111'
);

INSERT INTO transactions (account_id, transaction_type_id, amount, description, reference_account)
VALUES (@acc_id, 3, 50000.00, 'Transfer ke 2222222222', '2222222222');

-- Lihat hasilnya (daftar transaksi)
SELECT t.transaction_id, a.account_number, t.transaction_type_id, t.amount, t.description
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
ORDER BY t.transaction_date DESC;

--NOMOR 3
CREATE TRIGGER tr_LimitAccountsPerCustomer
ON accounts
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN (SELECT customer_id, COUNT(*) AS jml FROM accounts GROUP BY customer_id) c
        ON i.customer_id = c.customer_id
        WHERE c.jml >= 3
    )
    BEGIN
        RAISERROR('Customer sudah punya 3 akun', 16, 1);
        ROLLBACK;
        RETURN;
    END

    INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance, created_at)
    SELECT NEWID(), customer_id, account_number, account_type, balance, GETDATE()
    FROM inserted;
END;

INSERT INTO accounts (customer_id, account_number, account_type, balance)
VALUES ('d01d990c-8cbd-4b0f-87b3-4c31fafbf3d5', '0000000003', 'savings', 500000);

SELECT account_id, account_number, account_type, balance
FROM accounts
WHERE customer_id = 'd01d990c-8cbd-4b0f-87b3-4c31fafbf3d5';

--NOMOR 4
CREATE TRIGGER tr_BlockInvalidReferenceAccount
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.reference_account IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM accounts a
            WHERE a.account_id = i.reference_account
        )
    )
    BEGIN
		RAISERROR('Reference_account tidak ditemukan.', 16, 1);
        ROLLBACK;
		RETURN;
    END
END;

-- Pengujian
INSERT INTO transactions (account_id, transaction_type_id, amount, reference_account)
VALUES ('6edc13ce-6ed2-48a7-b73d-ef6ed8b73e38',3, 100000, '4734b927-4bba-4591-a8fc');

--NOMOR 5
CREATE TRIGGER tr_EnsureMinimumBalance
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

	-- Batalkan jika transaksi menyebabkan saldo akhir < 100.000
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.transaction_type_id IN (2, 3)
        AND (a.balance - i.amount) < 100000
    )
    BEGIN
        RAISERROR('Saldo setelah transaksi harus minimal Rp100.000.', 16, 1);
        ROLLBACK;
        RETURN;
    END

	-- Jika saldo mencukupi, lanjutkan transaksi
    INSERT INTO transactions (account_id, transaction_type_id, amount, description, reference_account)
    SELECT account_id, transaction_type_id, amount, description, reference_account
    FROM inserted;
END

-- Tambahkan akun untuk pengujian
INSERT INTO customers (first_name, last_name, email, phone_number, address)
VALUES ('Fauzan', 'A', 'fauzan@gmail.com', '08111222333', 'Surabaya');

DECLARE @cust_id CHAR(36) = (
    SELECT TOP 1 customer_id FROM customers WHERE first_name = 'Fauzan'
);
-- Akun dengan saldo Rp150.000
INSERT INTO accounts (customer_id, account_number, account_type, balance)
VALUES (@cust_id, '3333333333', 'savings', 150000.00);

-- Uji Transaksi DITOLAK (karena saldo akhir < 100.000)
DECLARE @acc_id CHAR(36) = (
    SELECT account_id FROM accounts WHERE account_number = '3333333333'
);
-- Tarik Rp60.000, hasil akhir = 90.000 < 100.000 (DITOLAK)
INSERT INTO transactions (account_id, transaction_type_id, amount, description)
VALUES (@acc_id, 2, 60000.00, 'Tarik tunai Rp60.000');

-- Uji Transaksi DITERIMA (saldo akhir >= 100.000)
DECLARE @acc_id CHAR(36) = (
    SELECT account_id FROM accounts WHERE account_number = '3333333333'
);
-- Tarik Rp30.000, hasil akhir = 120.000 (DITERIMA)
INSERT INTO transactions (account_id, transaction_type_id, amount, description)
VALUES (@acc_id, 2, 30000.00, 'Tarik tunai Rp30.000');

-- Lihat hasilnya (daftar transaksi)
SELECT t.transaction_id, a.account_number, t.transaction_type_id, t.amount, t.description
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
WHERE a.account_number = '3333333333'
ORDER BY t.transaction_date DESC;



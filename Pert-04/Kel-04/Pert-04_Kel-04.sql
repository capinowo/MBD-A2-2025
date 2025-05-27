USE bankdb;
GO

/* Nomor 1 */
CREATE TRIGGER tr_UpdateAccountBalance_BeforeTransaction
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cek jika saldo tidak mencukupi untuk penarikan atau transfer
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.transaction_type_id IN (2, 3) AND a.balance < i.amount
    )
    BEGIN
        RAISERROR ('Saldo tidak mencukupi untuk melakukan transaksi.', 16, 1);
        RETURN;
    END

    -- Update saldo akun
    UPDATE a
    SET a.balance = 
        CASE 
            WHEN i.transaction_type_id = 1 THEN a.balance + i.amount -- Deposit
            WHEN i.transaction_type_id IN (2, 3) THEN a.balance - i.amount -- Withdrawal / Transfer
            ELSE a.balance
        END
    FROM accounts a
    JOIN inserted i ON a.account_id = i.account_id;

    -- Masukkan transaksi ke tabel
    INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    SELECT 
        transaction_id, account_id, transaction_type_id, amount, 
        ISNULL(transaction_date, GETDATE()), description, reference_account
    FROM inserted;
END;
GO

SELECT * FROM transactions
WHERE account_id = '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7'
ORDER BY transaction_date DESC;

/* Nomor 2 */
CREATE INDEX search_desc
ON transactions(description);

/* Nomor 3 */
-- AKTIFKAN STATISTIK TIME & IO
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- UJI COBA SEBELUM ADA INDEX
SELECT * FROM accounts WHERE account_type = 'savings' AND balance > 10000;

-- PEMBUATAN INDEX
CREATE INDEX idx_acc_type_balance
	ON accounts(account_type, balance);

-- UJI COBA SETELAH ADA INDEX
SELECT * FROM accounts WHERE account_type = 'savings' AND balance > 10000;

-- PENGHAPUSAN INDEX
DROP INDEX idx_acc_type_balance ON accounts;

/* Nomor 4 */
DECLARE @account_id CHAR(36);
DECLARE @balance DECIMAL(18,2);

DECLARE read_accounts_cursor CURSOR FOR
SELECT account_id, balance
FROM accounts;

OPEN read_accounts_cursor;

FETCH NEXT FROM read_accounts_cursor INTO @account_id, @balance;

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @balance < 9000
	BEGIN
		PRINT 'Saldo rendah untuk account_id: ' + @account_id;
	END;

	FETCH NEXT FROM read_accounts_cursor INTO @account_id, @balance;
END;

CLOSE read_accounts_cursor;
DEALLOCATE read_accounts_cursor;

/* Nomor 5 */
DECLARE @first_name CHAR(50);
DECLARE @last_name VARCHAR(50);

-- Deklarasi cursor
DECLARE customer_cursor CURSOR FOR
SELECT first_name, last_name
FROM customers;

-- Buka cursor
OPEN customer_cursor;

-- Ambil baris pertama
FETCH NEXT FROM customer_cursor INTO @first_name, @last_name;

-- Loop selama masih ada data
WHILE @@FETCH_STATUS = 0

BEGIN
-- Cetak data (bisa diganti dengan proses lain)
PRINT 'Customer: ' + concat(@first_name, @last_name)
-- Ambil baris berikutnya
FETCH NEXT FROM customer_cursor INTO @first_name,
@last_name;
END;

-- Tutup dan hapus cursor
CLOSE customer_cursor;
DEALLOCATE customer_cursor;
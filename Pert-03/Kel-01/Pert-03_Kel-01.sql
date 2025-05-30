/* KELOMPOK 1 MBD A2
    - Fachryzaidan Akmal (24060122120001)
    - Raja Samuel Tarigan (24060122140157)
*/

/* No. 1
   Buat trigger tr_UpdateAccountBalance_BeforeTransaction ke tabel transactions yang 
   akan mencegah transaksi dilakukan jika saldo akun tidak cukup. Jika saldo < jumlah amount, 
   maka transaksi harus dibatalkan. Gunakan syntax Rollback.
*/
CREATE TRIGGER tr_UpdateAccountBalance_BeforeTransaction
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @account_id CHAR(36), @amount DECIMAL(18,2), @type_id INT, @balance DECIMAL(18,2);

    SELECT @account_id = account_id, @amount = amount, @type_id = transaction_type_id
    FROM inserted;

    SELECT @balance = balance FROM accounts WHERE account_id = @account_id;

    IF @type_id IN (2,3) AND @balance < @amount
    BEGIN
        RAISERROR ('Saldo tidak mencukupi untuk transaksi ini.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO transactions
    SELECT * FROM inserted;
END

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date)
VALUES (NEWID(), '07a36a4b-7943-4634-b17a-7c7eb4407cd3', 2, 1000000, GETDATE());

/* No. 2
   Buat trigger tr_Deposit_AfterTransaction ke tabel transactions yang aktif jika ada transaksi transfer 
   yang menambahkan transaksi baru ke akun tujuan (reference_account) dengan tipe transaksi deposit 
   dan nilai amount yang sama.
*/
CREATE TRIGGER tr_Deposit_AfterTransaction
ON transactions
AFTER INSERT
AS
BEGIN
    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount, transaction_date, description
    )
    SELECT
        NEWID(), reference_account, 1, amount, GETDATE(),
        CONCAT('Transfer diterima dari ', account_id)
    FROM inserted
    WHERE transaction_type_id = 3;
END

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, reference_account)
VALUES (NEWID(), '1118a259-aa7d-402b-9f1f-72555ed15180', 3, 2000, GETDATE(), '1d97bce1-5c94-49e4-8e2a-6ad56b99afb0');

DROP TRIGGER tr_Deposit_AfterTransaction
/* No. 3
   Buat trigger tr_LimitAccountsPerCustomer yang akan mencegah penambahan akun baru (accounts) 
   jika seorang nasabah (customer_id) sudah memiliki 3 akun. Trigger ini dijalankan sebelum insert 
   ke tabel accounts. Jika jumlah akun untuk customer_id >= 3, maka transaksi dibatalkan. 
   Gunakan syntax Rollback.
*/
CREATE TRIGGER tr_LimitAccountsPerCustomer
ON accounts
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @customer_id CHAR(36), @count INT;

    SELECT @customer_id = customer_id FROM inserted;

    SELECT @count = COUNT(*) FROM accounts WHERE customer_id = @customer_id;

    IF @count >= 3
    BEGIN
        RAISERROR('Customer sudah memiliki 3 akun. Tidak bisa menambahkan akun baru.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO accounts
    SELECT * FROM inserted;
END

INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance, created_at)
VALUES (NEWID(), '287bf982-89ce-44b5-bfdd-49407600309a', '1234567892', 'savings', 500000, GETDATE());

/* No. 4
   Buat trigger tr_BlockInvalidReferenceAccount pada tabel transactions yang aktif 
   jika terdapat insert transaksi transfer, sistem harus mengecek apakah akun tujuan (reference_account) 
   benar-benar ada di tabel accounts. Jika tidak ditemukan, batalkan transaksi. Gunakan syntax Rollback.
*/
CREATE TRIGGER tr_BlockInvalidReferenceAccount
ON transactions
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.transaction_type_id = 3
          AND NOT EXISTS (
              SELECT 1 FROM accounts a WHERE a.account_id = i.reference_account
          )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Akun tujuan transfer tidak valid.', 1;
    END
END

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, reference_account)
VALUES (NEWID(), '07a36a4b-7943-4634-b17a-7c7eb4407cd3', 3, 1000, GETDATE(), '0937445f-d5eb-4ef9-887f-5173fe662dd5');

/* No. 5
   Buat trigger tr_EnsureMinimumBalance di tabel transactions yang aktif saat transaksi withdrawal 
   atau transfer dilakukan. Trigger harus memeriksa apakah saldo akun setelah transaksi memiliki minimal
   Rp100.000. Jika tidak, transaksi dibatalkan. Gunakan syntax Rollback.
*/
CREATE TRIGGER tr_EnsureMinimumBalance
ON transactions
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.transaction_type_id IN (2, 3)
          AND (a.balance - i.amount) < 100000
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Saldo setelah transaksi harus minimal Rp100.000.', 1;
    END
END

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date)
VALUES (NEWID(), 'FECB4DA8-5502-44C6-867E-E67C6CC31D88', 2, 950000, GETDATE());
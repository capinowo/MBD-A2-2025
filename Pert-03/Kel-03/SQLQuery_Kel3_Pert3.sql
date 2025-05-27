use bank;
-- Trigger 

 -- i. Buat trigger tr_UpdateAccountBalance_BeforeTransaction ke tabel transactions yang akan 
 -- mencegah transaksi dilakukan jika saldo akun tidak cukup. Jika saldo < jumlah amount, maka transaksi harus dibatalkan. 
 -- Gunakan syntax Rollback. 

 -- drop trigger tr_UpdateAccountBalance_BeforeTransaction; 

CREATE TRIGGER tr_UpdateAccountBalance_BeforeTransaction
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cek saldo setiap transaksi yang akan dimasukkan
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.amount > a.balance
    )
    BEGIN
        RAISERROR('Saldo tidak mencukupi untuk transaksi ini.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Jika saldo mencukupi, izinkan insert
    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    )
    SELECT 
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    FROM inserted;
END;

--coba 
INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, 
transaction_date, description, reference_account)
VALUES (NEWID(), '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7', 1, 
10000.00, GETDATE(), 'Penarikan Besar', NULL);

-- coba transaksi berhasil
SELECT balance FROM accounts WHERE account_id = '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7';
-- Saldo: 9038.34

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, 
transaction_date, description, reference_account)
VALUES (NEWID(), '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7', 1, 
1000.00, GETDATE(), 'Pembayaran Tagihan', NULL);


-- ii. Buat trigger tr_Deposit_AfterTransaction ke tabel transactions yang aktif jika ada transaksi 
-- transfer yang menambahkan transaksi baru ke akun tujuan (reference_account) dengan tipe 
-- transaksi deposit dan nilai amount yang sama. 

CREATE TRIGGER tr_Deposit_AfterTransaction
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO transactions (
        transaction_id,
        account_id,
        transaction_type_id,
        amount,
        transaction_date,
        description,
        reference_account
    )
    SELECT 
        NEWID(),                      
        i.reference_account, 1, i.amount, GETDATE(), LEFT(CONCAT('Transfer received from account ', i.account_id), 50),
		i.account_id      
    FROM inserted i
    WHERE i.transaction_type_id = 2 AND i.reference_account IS NOT NULL;
END;

-- coba transaksi
INSERT INTO transactions (
    transaction_id,
    account_id,
    transaction_type_id,
    amount,
    transaction_date,
    description,
    reference_account
)
VALUES (
    NEWID(),
    '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7', -- pengirim
    2,                                     -- transfer
    500.00,
    GETDATE(),
    'Transfer ke akun lain',
    '905660c8-d6a7-40e9-9be3-e6711d22efb6'  -- penerima
);

-- cek hasil 
SELECT * 
FROM transactions 
WHERE account_id = '905660c8-d6a7-40e9-9be3-e6711d22efb6';

-- iii. Buat trigger tr_LimitAccountsPerCustomer yang akan mencegah penambahan akun baru (accounts) 
-- jika seorang nasabah (customer_id) sudah memiliki 3 akun. Trigger ini dijalankan sebelum insert ke tabel accounts. 
-- Jika jumlah akun untuk customer_id >= 3, maka transaksi dibatalkan. Gunakan syntax Rollback. 

CREATE TRIGGER tr_LimitAccountsPerCustomer
ON accounts
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cek apakah ada customer yang sudah memiliki >= 3 akun
    IF EXISTS (
        SELECT i.customer_id
        FROM inserted i
        JOIN accounts a ON i.customer_id = a.customer_id
        GROUP BY i.customer_id
        HAVING COUNT(a.account_id) >= 3
    )
    BEGIN
        RAISERROR('Customer ini sudah memiliki 3 akun. Tidak dapat menambahkan akun baru.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Jika lolos validasi, lanjutkan insert
    INSERT INTO accounts (
        account_id, customer_id, account_number, account_type, balance, created_at
    )
    SELECT 
        account_id, customer_id, account_number, account_type, balance, created_at
    FROM inserted;
END;

-- cari customer dengan 3 akun 
SELECT customer_id, COUNT(*) AS account_count
FROM accounts
GROUP BY customer_id
HAVING COUNT(*) = 3;


-- coba masukkan akun baru
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
VALUES
('new-account-id-1', '9d78736f-df51-4622-9cb1-c4db88dca2d0', '1234567890', 'savings', 1000.00),
('new-account-id-2', '9d78736f-df51-4622-9cb1-c4db88dca2d0', '1234567891', 'current', 1500.00),
('new-account-id-3', 'f8628b73-c900-4973-849e-22aa8e42fc33', '1234567892', 'credit', 2000.00),
('new-account-id-4', 'f8628b73-c900-4973-849e-22aa8e42fc33', '1234567893', 'savings', 2500.00),
('new-account-id-5', '3f5ab011-f526-4bbd-8ab8-8a67ad95c5bf', '1234567894', 'current', 3000.00),
('new-account-id-6', '3f5ab011-f526-4bbd-8ab8-8a67ad95c5bf', '1234567895', 'credit', 3500.00);


-- iv. Buat trigger tr_BlockInvalidReferenceAccount pada tabel transactions yang aktif jika terdapat 
-- insert transaksi transfer, sistem harus mengecek apakah akun tujuan (reference_account) benar-benar ada di tabel accounts. 
-- Jika tidak ditemukan, batalkan transaksi. Gunakan syntax Rollback. 
 
-- drop trigger tr_BlockInvalidReferenceAccount;

CREATE TRIGGER tr_BlockInvalidReferenceAccount
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cek apakah ada transaksi transfer yang reference_account-nya tidak valid
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.transaction_type_id = 2  -- Asumsikan 2 = transfer
        AND (
            i.reference_account IS NULL
            OR NOT EXISTS (
                SELECT 1
                FROM accounts a
                WHERE a.account_id = i.reference_account
            )
        )
    )
    BEGIN
        RAISERROR('Akun tujuan (reference_account) tidak valid atau tidak ditemukan.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Jika semua valid, lanjutkan insert
    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    )
    SELECT 
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    FROM inserted;
END;

-- pengujian 
INSERT INTO transactions (
    transaction_id,
    account_id,
    transaction_type_id,
    amount,
    transaction_date,
    description,
    reference_account
)
VALUES (
    NEWID(),
    '8c46fae1-9789-4427-8440-7cf48a0272cd', 
    2,  
    100.00,
    GETDATE(),
    'Transfer ke akun tidak valid',
    '00000000-0000-0000-0000-000000000000'  
);


-- v. Buat trigger tr_EnsureMinimumBalance di tabel transactions yang aktif saat transaksi withdrawal 
-- atau transfer dilakukan. Trigger harus memeriksa apakah saldo akun setelah transaksi memiliki 
-- minimal Rp100.000. Jika tidak, transaksi dibatalkan. Gunakan syntax Rollback. 

CREATE TRIGGER tr_EnsureMinimumBalance
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Trigger hanya aktif untuk transaksi withdrawal (id=3) atau transfer (id=2)
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.transaction_type_id IN (2, 3)  -- 2: Transfer, 3: Withdrawal
        AND (a.balance - i.amount) < 100000
    )
    BEGIN
        RAISERROR('Saldo tidak mencukupi. Minimal saldo setelah transaksi harus Rp100.000.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Jika validasi lolos, izinkan insert
    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    )
    SELECT 
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    FROM inserted;
END;


-- pengujian
BEGIN TRANSACTION;
INSERT INTO transactions (account_id, transaction_type_id, amount, transaction_date, description)
VALUES ('9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7', 3, 9000, GETDATE(), 'Failed Withdrawal');
COMMIT TRANSACTION;

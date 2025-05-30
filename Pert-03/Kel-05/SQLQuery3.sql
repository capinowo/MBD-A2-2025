-- 1. trigger tr_UpdateAccountBalance_BeforeTransaction
CREATE TRIGGER tr_UpdateAccountBalance_BeforeTransaction
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.amount > a.balance
    )
    BEGIN
        RAISERROR('Transaksi ditolak. Saldo tidak mencukupi.', 16, 1);
        ROLLBACK;
        RETURN;
    END
    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    )
    SELECT
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    FROM inserted;
END;

INSERT INTO transactions (
    transaction_id, account_id, transaction_type_id, amount,
    transaction_date, description
)
VALUES (
    NEWID(), '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7', 3, 999999999, GETDATE(), 'Penarikan tidak sah'
);


-- 2. trigger tr_Deposit_AfterTransaction
CREATE TRIGGER tr_Deposit_AfterTransaction
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    )
    SELECT
        NEWID(),                              -- ID transaksi baru
        i.reference_account,                  -- Akun tujuan
        tt_deposit.transaction_type_id,       -- ID untuk transaksi 'Deposit'
        i.amount,                             -- Nominal yang sama
        GETDATE(),                            -- Tanggal transaksi saat ini
        'Auto deposit from transfer',         -- Deskripsi
        i.account_id                          -- Referensi balik ke akun asal
    FROM inserted i
    JOIN transaction_types tt_transfer ON i.transaction_type_id = tt_transfer.transaction_type_id
    JOIN transaction_types tt_deposit ON tt_deposit.name = 'Deposit'
    WHERE tt_transfer.name = 'Transfer'
      AND i.reference_account IS NOT NULL;
END;

INSERT INTO transactions (
    transaction_id, account_id, transaction_type_id, amount, description, reference_account
)
VALUES (
    NEWID(), 
    '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7', -- akun asal
    2,                                     -- 2 = Transfer
    500000,
    'Transfer ke akun B',
    'e0c672fd-8182-42b1-8a70-2138f223c47c'  -- akun tujuan
);

SELECT * FROM transactions
WHERE description = 'Uji transfer ke akun B'
   OR description = 'Auto deposit from transfer';

-- 3. trigger tr_LimitAccountsPerCustomer
CREATE TRIGGER tr_LimitAccountsPerCustomer
ON accounts
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT i.customer_id
        FROM inserted i
        GROUP BY i.customer_id
        HAVING (
            SELECT COUNT(*)
            FROM accounts a
            WHERE a.customer_id = i.customer_id
        ) >= 3
    )
    BEGIN
        RAISERROR ('Nasabah sudah memiliki 3 akun. Tidak dapat menambahkan akun baru.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance, created_at)
    SELECT account_id, customer_id, account_number, account_type, balance, created_at
    FROM inserted;
END;

INSERT INTO accounts (customer_id, account_number, account_type, balance)
VALUES ('5b3fb023-fd43-4cae-8783-ef1c98d11b38', '9999999999', 'savings', 5000.00);

-- 4. trigger tr_BlockInvalidReferenceAccount
CREATE TRIGGER tr_BlockInvalidReferenceAccount
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.transaction_type_id = 2
          AND (
              i.reference_account IS NULL OR
              NOT EXISTS (
                  SELECT 1
                  FROM accounts a
                  WHERE a.account_id = i.reference_account
              )
          )
    )
    BEGIN
        RAISERROR ('Transaksi transfer gagal: reference_account tidak valid.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account)
    SELECT transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account
    FROM inserted;
END;

INSERT INTO transactions (account_id, transaction_type_id, amount, description, reference_account)
VALUES (
    '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7',
    2, -- transfer
    1000.00,
    'Transfer to invalid account',
    '00000000-0000-0000-0000-000000000000'
);

-- 5. trigger tr_EnsureMinimumBalance
CREATE TRIGGER tr_EnsureMinimumBalance
ON transactions
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN transaction_types tt ON i.transaction_type_id = tt.transaction_type_id
        WHERE tt.name IN ('Withdrawal', 'Transfer')
    )
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN transaction_types tt ON i.transaction_type_id = tt.transaction_type_id
            JOIN accounts a ON i.account_id = a.account_id
            WHERE tt.name IN ('Withdrawal', 'Transfer')
              AND (a.balance - i.amount) < 100000
        )
        BEGIN
            RAISERROR('Transaksi ditolak. Saldo akhir tidak boleh kurang dari Rp100.000.', 16, 1);
            ROLLBACK;
            RETURN;
        END
    END

    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    )
    SELECT
        transaction_id, account_id, transaction_type_id, amount,
        transaction_date, description, reference_account
    FROM inserted;
END;

INSERT INTO transactions (
    transaction_id, account_id, transaction_type_id, amount, description
)
VALUES (
    NEWID(), '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7', 3, 9000000, 'Penarikan berlebihan'
);

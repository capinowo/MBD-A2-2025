use bankdb;

-- NO 1 --
GO
CREATE TRIGGER tr_UpdateAccountBalance_BeforeTransaction
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON i.account_id = a.account_id
        WHERE i.transaction_type_id IN (2,3) 
          AND a.balance < i.amount
    )
    BEGIN
        ROLLBACK;

        RAISERROR ('Transaksi dibatalkan: saldo tidak mencukupi.', 16, 1);
        RETURN;
    END
END


INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount)
VALUES ('TXN003', '07a36a4b-7943-4634-b17a-7c7eb4407cd3', 3, 11000.00);


SELECT * FROM transactions where account_id = 'c098f0dd-6434-4f69-afdd-d756849fe1fd';
select * from transaction_types;
select * from accounts where customer_id = '287bf982-89ce-44b5-bfdd-49407600309a';

-- NO 2 --
GO
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
        i.reference_account,       
        1,                         
        i.amount,                  
        GETDATE(),                 
        'Deposit otomatis dari transfer',
        i.account_id               
    FROM inserted i
    WHERE i.transaction_type_id = 3; 
END;

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account)
VALUES (NEWID(), 'c098f0dd-6434-4f69-afdd-d756849fe1fd', 3, 100.00, GETDATE(), 'Transfer ke acc-222', 'f75c87e7-70a8-4fbd-8ad6-9d5e9cefc314');

SELECT * FROM transactions
WHERE (account_id = 'c098f0dd-6434-4f69-afdd-d756849fe1fd' OR account_id = 'f75c87e7-70a8-4fbd-8ad6-9d5e9cefc314') AND amount = 100.00
ORDER BY transaction_date DESC;

-- NO 3 --
GO
CREATE TRIGGER tr_LimitAccountsPerCustomer
ON accounts
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN (
            SELECT customer_id, COUNT(*) AS account_count
            FROM accounts
            GROUP BY customer_id
        ) a ON i.customer_id = a.customer_id
        WHERE a.account_count >= 3
    )
    BEGIN
        RAISERROR('Setiap nasabah hanya boleh memiliki maksimal 3 akun.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    INSERT INTO accounts (account_id, customer_id, account_type, balance)
    SELECT account_id, customer_id, account_type, balance
    FROM inserted;
END;

INSERT INTO accounts (account_id, customer_id, account_type, balance)
VALUES (NEWID(), '287bf982-89ce-44b5-bfdd-49407600309a', 'savings', 1000.00);

SELECT customer_id, COUNT(*) AS jumlah_akun
FROM accounts
WHERE customer_id = '287bf982-89ce-44b5-bfdd-49407600309a'
GROUP BY customer_id;


-- NO 4 --
GO
CREATE TRIGGER tr_BlockInvalidReferenceAccount
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cek apakah ada reference_account yang tidak ditemukan di tabel accounts
    IF EXISTS (
        SELECT 1
        FROM inserted i --menggunakan inserted untuk tabel baru dan tidak menggunakan tabel transaksi
        LEFT JOIN accounts a ON i.reference_account = a.account_id
        WHERE i.reference_account IS NOT NULL AND a.account_id IS NULL
    )
    BEGIN
        ROLLBACK;
        RAISERROR('Transaksi dibatalkan: reference_account tidak ditemukan di tabel accounts.', 16, 1);
    END
END;

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account)
VALUES ('f49e2d66-5fcc-45fb-ac4c-6c51b826f78e',	'905660c8-d6a7-40e9-9be3-e6711d22efb6',	3	
		,118.44	, 2025-03-21,'Affectus et firmitatem animi nec mortem nec dolore',	'4734b927-4bba-4591-a8fc-caf19a15faed');


-- NO 5 --
GO
CREATE TRIGGER tr_EnsureMinimumBalance
ON transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cek apakah ada transaksi withdrawal atau transfer yang menyebabkan saldo < 100000
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN accounts a ON a.account_id = i.account_id
        WHERE i.transaction_type_id IN (2, 3)
          AND (a.balance - i.amount) < 100000
    )
    BEGIN
        -- Batalkan transaksi dengan rollback
        ROLLBACK TRANSACTION;
        RAISERROR('Saldo minimal Rp 100.000 harus dipertahankan setelah transaksi.', 16, 1);
        RETURN;
    END
END;

DECLARE @acc CHAR(36) = (SELECT TOP 1 account_id FROM accounts WHERE account_number = '8346813622');

INSERT INTO transactions (account_id, transaction_type_id, amount, description)
VALUES (@acc, 2, 20000, 'Tarik tunai');
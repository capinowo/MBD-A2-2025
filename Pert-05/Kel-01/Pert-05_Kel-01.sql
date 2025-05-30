/* KELOMPOK 1 MBD A2
    - Fachryzaidan Akmal (24060122120001)
    - Raja Samuel Tarigan (24060122140157)
*/

/* 1. 
Buat view vw_recent_high_value_transactions yang menampilkan
transaksi 30 hari terakhir dengan nilai > rata-rata seluruh transaksi. */

CREATE VIEW vw_recent_high_value_transactions AS
SELECT * FROM transactions
WHERE transaction_date >= DATEADD(DAY, -30, GETDATE())
  AND amount > (
      SELECT AVG(amount) FROM transactions
  );

SELECT * FROM vw_recent_high_value_transactions;

/* 2. 
Buat view yang menampilkan jumlah transaksi per akun, dengan
memisahkan transaksi deposit, transfer, dan withdrawal dalam kolom
berbeda. */

CREATE VIEW vw_transaction_counts_per_account AS
SELECT 
	accounts.account_id,
	COUNT(CASE WHEN transaction_types.name = 'deposit' THEN 1 END) AS deposit_count,
	COUNT(CASE WHEN transaction_types.name = 'transfer' THEN 1 END) AS transfer_count, 
	COUNT(CASE WHEN transaction_types.name = 'withdrawal' THEN 1 END) AS withdrawal_count
FROM accounts
LEFT JOIN transactions ON accounts.account_id = transactions.account_id
LEFT JOIN transaction_types ON transactions.transaction_type_id = transaction_types.transaction_type_id
GROUP BY accounts.account_id;

SELECT * FROM vw_transaction_counts_per_account;

/* 5. 
Buat function fn_customer_loans_info yang mengembalikan list semua
pinjaman customer lengkap dengan status dan selisih antara end_date dan
GETDATE(). */

CREATE FUNCTION fn_customer_loans_info (@customer_id CHAR(36))
RETURNS TABLE
AS
RETURN (
    SELECT loan_id, loan_amount, status, end_date, DATEDIFF(DAY, GETDATE(), end_date) AS days_remaining
    FROM loans WHERE customer_id = @customer_id
);

SELECT * FROM fn_customer_loans_info('14f35ff7-5574-4e12-ad89-7e7704a02e62');

/* 7. 
Cegah transaksi baru yang memiliki transaction_date lebih lama dari
transaksi terakhir untuk akun yang melakukan transaksi tersebut. */
CREATE TRIGGER tr_PreventBackdatedTransaction
ON transactions
INSTEAD OF INSERT
AS
BEGIN
	IF EXISTS (
        SELECT 1
        FROM inserted
        JOIN (
            SELECT account_id, MAX(transaction_date) AS last_date
            FROM transactions
            GROUP BY account_id
        ) transactions ON inserted.account_id = transactions.account_id
        WHERE inserted.transaction_date < transactions.last_date
    )
    BEGIN
        RAISERROR('Tidak boleh memasukkan transaksi dengan tanggal lebih lama dari transaksi terakhir untuk akun ini.', 16, 1);
        ROLLBACK;
        RETURN;
    END

    INSERT INTO transactions (
        transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account
    )
    SELECT
        transaction_id, account_id, transaction_type_id, amount, transaction_date, description, reference_account
    FROM inserted;
END;

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, description)
VALUES (NEWID(), '07a36a4b-7943-4634-b17a-7c7eb4407cd3', 1, 100000, '2024-01-01', 'Tes backdate');

INSERT INTO transactions (transaction_id, account_id, transaction_type_id, amount, transaction_date, description)
VALUES (NEWID(), '07a36a4b-7943-4634-b17a-7c7eb4407cd3', 1, 100000, GETDATE(), 'Transaksi valid');
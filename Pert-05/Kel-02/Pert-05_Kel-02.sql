-- NO 1 --
-- Buat view vw_recent_high_value_transactions yang menampilkan
-- transaksi 30 hari terakhir dengan nilai > rata-rata seluruh transaksi.

CREATE VIEW vw_recent_high_value_transactions AS
SELECT *
FROM transactions
WHERE transaction_date >= DATEADD(DAY, -30, GETDATE())
  AND amount > (
      SELECT AVG(amount)
      FROM transactions
  );

SELECT * FROM vw_recent_high_value_transactions;

select * from transaction_types

-- NO 2 --
-- Buat view yang menampilkan jumlah transaksi per akun, dengan
-- memisahkan transaksi deposit, transfer, dan withdrawal dalam kolom
-- berbeda.
CREATE VIEW vw_transaction_count_per_account AS
SELECT
	account_id AS customerId,
	SUM(CASE WHEN transaction_type_id = 1 THEN 1 ELSE 0 END) AS deposit,
	SUM(CASE WHEN transaction_type_id = 2 THEN 1 ELSE 0 END) AS transfer,
	SUM(CASE WHEN transaction_type_id = 3 THEN 1 ELSE 0 END) AS withdrawal
FROM transactions
GROUP BY account_id;

select * from vw_transaction_count_per_account;

-- NO 5 --
--Buat function fn_customer_loans_info yang mengembalikan list semua
--pinjaman customer lengkap dengan status dan selisih antara end_date dan
--GETDATE().
use bankdb;

GO
CREATE FUNCTION fn_customer_loans_info ()
RETURNS TABLE
AS
RETURN (
	SELECT loan_id AS LoanId,
	loan_amount AS LoanAmount,
	interest_rate AS InterestRate,
	loan_terms_months AS LoanTermsMonth,
	start_date AS StartDate,
    end_date AS EndDate,
	status AS Status,
	ABS(DATEDIFF(DAY, GETDATE(), end_date)) AS SisaHari
	FROM loans
);
GO

SELECT * FROM fn_customer_loans_info();
drop function fn_customer_loans_info;

-- NO 7 --
-- Cegah transaksi baru yang memiliki transaction_date lebih lama dari
-- transaksi terakhir untuk akun yang melakukan transaksi tersebut.
CREATE TRIGGER transaction_date
ON transactions
INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(
		SELECT 1 FROM inserted i 
		JOIN (SELECT account_id, MAX(transaction_date) AS tanggal_terakhir
		FROM transactions GROUP BY account_id) t ON i.account_id = t.account_id
		WHERE i.transaction_date < t.tanggal_terakhir)

	BEGIN 
		RAISERROR('Transaction outdated', 16, 1)
		ROLLBACK TRANSACTION;
		RETURN;
	END

	INSERT INTO transactions(account_id, transaction_type_id, amount, transaction_date)
	SELECT account_id, transaction_type_id, amount, transaction_date
	FROM inserted;
END


INSERT INTO transactions(account_id, transaction_type_id, amount, transaction_date)
VALUES ('802b2efe-e1d1-465b-940f-5cf573a2c985', 2, 100, 2024-10-16)

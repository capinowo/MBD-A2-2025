USE BANKDB;
GO

-- NOMOR 1
CREATE VIEW v_customer_all AS
SELECT * FROM customers;
GO

SELECT * FROM v_customer_all;
GO

-- NOMOR 2
CREATE VIEW v_deposit_transaction AS
SELECT * FROM transactions
WHERE transaction_type_id = 1;
GO

SELECT * FROM v_deposit_transaction;
GO

-- NOMOR 3
CREATE VIEW v_transfer_transaction AS
SELECT
	t.transaction_id AS IdTransaksi,
	t.account_id AS IdAkun,
	t.amount AS Jumlah,
	t.transaction_type_id AS IDJenisTransaksi
FROM dbo.transactions t
JOIN dbo.transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
WHERE t.transaction_type_id = 2;
GO

SELECT * FROM v_transfer_transaction;
GO
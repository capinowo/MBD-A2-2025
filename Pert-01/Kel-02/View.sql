-- view v_customer_all menampilkan semua isi tabel customers.
CREATE VIEW v_customer_all AS SELECT * FROM customers;
SELECT * FROM v_customer_all;

-- view v_deposit_transaction menampilkan semua transaksi deposit.
CREATE VIEW v_deposit_transaction AS SELECT * FROM transactions WHERE transaction_type_id = 1;
SELECT * FROM v_deposit_transaction;

-- view v_transfer_transaction menampilkan semua transaksi transfer.
CREATE VIEW v_transfer_transaction AS SELECT * FROM transactions WHERE transaction_type_id = 2;
SELECT * FROM v_transfer_transaction;


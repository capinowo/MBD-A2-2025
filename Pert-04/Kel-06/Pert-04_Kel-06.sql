USE BANKDB;

-- Menghapus index
DROP INDEX emailcustomer ON customers;

-- Membuat index
CREATE INDEX emailcustomer 
  ON customers(email);

DECLARE @customer_id CHAR(36);
DECLARE @email VARCHAR(255);

-- Deklarasi cursor
DECLARE customer_cursor CURSOR FOR
SELECT customer_id, email 
FROM customers;

-- Buka cursor
OPEN customer_cursor;

-- Ambil baris pertama
FETCH NEXT FROM customer_cursor INTO @customer_id, @email;

-- Loop selama masih ada data
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Cetak data (bisa diganti dengan proses lain)
    PRINT 'Customer ID: ' + @customer_id + ' | Email: ' + @email;

    -- Ambil baris berikutnya
    FETCH NEXT FROM customer_cursor INTO @customer_id, @email;
END;

-- Tutup dan hapus cursor
CLOSE customer_cursor;
DEALLOCATE customer_cursor;



-- Tugas 

-- ============================================
-- TUGAS 1: Index pada kolom account_number
-- ============================================
-- DROP INDEX jika sudah pernah dibuat
DROP INDEX idx_account_number ON accounts;

-- Membuat INDEX pada kolom account_number
CREATE INDEX idx_account_number ON accounts(account_number);

-- Cek beberapa data account_number
SELECT TOP 10 account_number FROM accounts;

-- Pengujian: Jalankan query pencarian berdasarkan account_number
SELECT * FROM accounts WHERE account_number = '002';

-- Alasan:
-- Kolom account_number sangat cocok untuk diindeks karena sering digunakan 
-- dalam proses pencarian atau transaksi dan nilainya unik.



-- ============================================
-- TUGAS 2: Index pada kolom transaction_date
-- ============================================
-- DROP INDEX jika sudah pernah dibuat
DROP INDEX idx_transaction_date ON transactions;

-- Membuat INDEX pada kolom transaction_date
CREATE INDEX idx_transaction_date ON transactions(transaction_date);

-- Cek data tanggal transaksi
SELECT TOP 10 transaction_date FROM transactions ORDER BY transaction_date DESC;

-- Pengujian
SELECT * FROM transactions 
WHERE transaction_date >= '2024-01-01';

-- Alasan:
-- transaction_date sering digunakan dalam filter laporan mutasi transaksi berdasarkan waktu.



-- ============================================
-- TUGAS 3: Composite Index pada account_type dan created_at
-- ============================================
-- DROP INDEX jika sudah pernah dibuat
DROP INDEX idx_type_created ON accounts;

-- Pengujian performa SEBELUM membuat index
SELECT * FROM accounts
WHERE account_type = 'savings' AND created_at >= '2024-01-01';

-- Membuat INDEX pada kolom account_type, created_at
CREATE INDEX idx_type_created ON accounts(account_type, created_at);

-- Cek data kombinasi
SELECT TOP 10 account_type, created_at FROM accounts ORDER BY created_at DESC;

-- Pengujian
SELECT * FROM accounts 
WHERE account_type = 'savings' AND created_at >= '2024-01-01';

-- Alasan:
-- Kombinasi kolom ini sangat umum digunakan dalam laporan pembukaan akun berdasarkan jenis dan tanggal.



-- ============================================
-- TUGAS 4: Cursor (misal: Saldo < 200000)
-- ============================================
-- Buat tabel sementara untuk hasil
CREATE TABLE #LowBalanceAccounts (
    account_id CHAR(36),
    balance DECIMAL
);

-- Variabel dan cursor
DECLARE @account_id CHAR(36);
DECLARE @balance DECIMAL;

DECLARE akun_cursor CURSOR FOR
SELECT account_id, balance FROM accounts;

OPEN akun_cursor;
FETCH NEXT FROM akun_cursor INTO @account_id, @balance;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @balance < 200000
    BEGIN
        INSERT INTO #LowBalanceAccounts(account_id, balance)
        VALUES (@account_id, @balance);
    END
    FETCH NEXT FROM akun_cursor INTO @account_id, @balance;
END;

-- Tutup cursor
CLOSE akun_cursor;
DEALLOCATE akun_cursor;

-- Tampilkan hasil
SELECT 'Saldo rendah untuk account_id: ' + account_id AS Warning, balance
FROM #LowBalanceAccounts;

-- Hapus tabel sementara
DROP TABLE #LowBalanceAccounts;



-- ============================================
-- TUGAS 5: Cursor - Gabungkan Nama Pelanggan
-- ============================================
-- Buat tabel sementara untuk hasil
CREATE TABLE #CustomerNames (
    customer_name VARCHAR(200)
);

-- Variabel dan cursor
DECLARE @first_name VARCHAR(100);
DECLARE @last_name VARCHAR(100);

DECLARE nama_cursor CURSOR FOR 
SELECT first_name, last_name FROM customers;

OPEN nama_cursor;
FETCH NEXT FROM nama_cursor INTO @first_name, @last_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #CustomerNames(customer_name)
    VALUES ('Customer: ' + @first_name + ' ' + @last_name);
    FETCH NEXT FROM nama_cursor INTO @first_name, @last_name;
END;

-- Tutup cursor
CLOSE nama_cursor;
DEALLOCATE nama_cursor;

-- Tampilkan hasil
SELECT * FROM #CustomerNames;

-- Hapus tabel sementara
DROP TABLE #CustomerNames;
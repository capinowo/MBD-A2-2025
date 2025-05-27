-- i. Buatlah index pada tabel accounts untuk mempercepat pencarian. Pilih 
-- salah satu kolom pada table tersebut dan berikan alasan pemilihan kolom 
-- tersebut sebagai index!

CREATE INDEX InAccount_Id  
ON accounts ( account_id ); 


-- ii. Buatlah index pada tabel transactions untuk mempercepat pencarian. Pilih 
-- salah satu kolom pada table tersebut dan berikan alasan pemilihan kolom 
-- tersebut sebagai index! 

CREATE INDEX InTrans
ON transactions (transaction_id); 

-- iii. Buatlah composite index pada tabel accounts. Pilih lebih dari satu kolom 
-- pada tabel tersebut dan uji performa query sebelum dan setelah 
-- menggunakan index! (query pengujian berdasarkan kolom yang dipilih 
-- sebagai index)

CREATE INDEX In_acc_type_balance 
ON accounts(account_type, balance);

--pemanggilan 
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * FROM accounts
WHERE account_type = 'savings' AND balance > 10000;


-- iv. Buat cursor untuk membaca semua akun dari tabel accounts, lalu periksa 
-- balance masing-masing. Jika balance < 9.000, tampilkan pesan: "Saldo 
-- rendah untuk account_id: [account_id]".

DECLARE @account_id CHAR(36);
DECLARE @balance DECIMAL(18,2);

DECLARE cur_kun_counts CURSOR  
FOR 
	SELECT account_id, balance
    FROM accounts;
OPEN cur_kun_counts 
FETCH NEXT FROM cur_kun_counts INTO @account_id, @balance;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @balance < 9000
    BEGIN
        PRINT 'Saldo rendah untuk account_id: ' + @account_id;
    END

    FETCH NEXT FROM cur_kun_counts INTO @account_id, @balance;
END

CLOSE cur_kun_counts;
DEALLOCATE cur_kun_counts;


-- Buat cursor untuk membaca semua pelanggan (customers) dan gabungkan 
-- first_name dan last_name untuk ditampilkan dengan format: "Customer: 
-- [Nama Lengkap]".

DECLARE @first_name VARCHAR(50);
DECLARE @last_name VARCHAR(50);

DECLARE cur_customers CURSOR
FOR
    SELECT first_name, last_name
    FROM customers;

OPEN cur_customers;
FETCH NEXT FROM cur_customers INTO @first_name, @last_name;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Customer: ' + @first_name + ' ' + @last_name;

    FETCH NEXT FROM cur_customers INTO @first_name, @last_name;
END
CLOSE cur_customers;
DEALLOCATE cur_customers;
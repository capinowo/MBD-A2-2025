/* KELOMPOK 1 MBD A2
    - Fachryzaidan Akmal (24060122120001)
    - Raja Samuel Tarigan (24060122140157)
*/

/* No. 1
   Buatlah index pada tabel accounts untuk mempercepat pencarian. Pilih salah satu kolom pada table tersebut 
   dan berikan alasan pemilihan kolom tersebut sebagai index!
*/
CREATE INDEX idx_cust_id ON accounts(customer_id);
GO

SELECT * FROM accounts WHERE customer_id = 'b5c6a70e-f40c-43ac-9291-418539d54ae7';

/* Alasan pemilihan kolom customer_id sebagai index adalah karena kolom tersebut digunakan untuk mengambil seluruh akun milik customer tertentu */

/* No. 2
   Buatlah index pada tabel transactions untuk mempercepat pencarian. Pilih salah satu kolom pada table tersebut 
   dan berikan alasan pemilihan kolom tersebut sebagai index!
*/
CREATE INDEX idx_acc_id ON transactions(account_id);
GO

SELECT * FROM transactions WHERE account_id = '802b2efe-e1d1-465b-940f-5cf573a2c985';

/* Alasan pemilihan kolom account_id sebagai index adalah karena transaksi umumnya dicari berdasarkan account_id */

/* No. 3
   Buatlah composite index pada tabel accounts. Pilih lebih dari satu kolom pada tabel tersebut dan uji performa query sebelum dan setelah 
   menggunakan index! (query pengujian berdasarkan kolom yang dipilih sebagai index)
*/
CREATE INDEX idx_custid_acctype ON accounts(customer_id, account_type);

SELECT * FROM accounts WHERE customer_id = '287bf982-89ce-44b5-bfdd-49407600309a' AND account_type = 'savings';

/* No. 4
   Buat cursor untuk membaca semua akun dari tabel accounts, lalu periksa balance masing-masing. 
   Jika balance < 9.000, tampilkan pesan: "Saldo rendah untuk account_id: [account_id]".
*/
DECLARE @acc_id CHAR(36);
DECLARE @balance DECIMAL(10,2);

DECLARE acc_cursor CURSOR FOR
SELECT account_id, balance FROM accounts;

OPEN acc_cursor;
FETCH NEXT FROM acc_cursor INTO @acc_id, @balance;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @balance < 9000
    BEGIN
        PRINT CONCAT('Saldo rendah untuk account_id: ', @acc_id);
    END

    FETCH NEXT FROM acc_cursor INTO @acc_id, @balance;
END

CLOSE acc_cursor;
DEALLOCATE acc_cursor;

/* No. 5
   Buat cursor untuk membaca semua pelanggan (customers) dan gabungkan 
   first_name dan last_name untuk ditampilkan dengan format: "Customer: [Nama Lengkap]".
*/
DECLARE @first_name VARCHAR(50);
DECLARE @last_name VARCHAR(50);
DECLARE @full_name VARCHAR(101);

DECLARE cust_cursor CURSOR FOR
SELECT first_name, last_name FROM customers;

OPEN cust_cursor;
FETCH NEXT FROM cust_cursor INTO @first_name, @last_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @full_name = CONCAT(@first_name, ' ', @last_name);
    PRINT CONCAT('Customer: ', @full_name);

    FETCH NEXT FROM cust_cursor INTO @first_name, @last_name;
END

CLOSE cust_cursor;
DEALLOCATE cust_cursor;
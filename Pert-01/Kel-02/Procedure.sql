--Nomor1
--Procedure untuk menambahkan customer baru--
CREATE PROCEDURE sp_CreateCustomer 
	@first_name VARCHAR(50), 
	@last_name VARCHAR(50),
	@email VARCHAR(50), 
	@phone_number VARCHAR(20), 
	@address varchar(255)
AS
BEGIN 
	INSERT INTO customers (first_name, last_name, email, phone_number, address) 
	VALUES (@first_name, @last_name, @email, @phone_number, @address)
END;

EXEC sp_CreateCustomer
	@first_name = 'John',
    @last_name = 'Doe',
    @email = 'john.doe@example.com',
    @phone_number = '08123456789',
    @address = 'Jl. Sudirman No. 10, Jakarta';

--Nomor 2
--Procedure untuk menambahkan akun baru untuk customer yang sudah ada--
CREATE PROCEDURE Sp_CreateAccount
	@customer_id CHAR(36),
	@account_number CHAR(10),
	@account_type VARCHAR(50),
	@balance DECIMAL(18,2)
AS
BEGIN
	IF EXISTS (SELECT  1 FROM customers WHERE customer_id = @customer_id)
	BEGIN
		INSERT INTO accounts (customer_id, account_number, account_type, balance)
		VALUES(@customer_id, @account_number, @account_type, @balance);
	END
  ELSE
  BEGIN
    RAISERROR('Customer tidak ditemukan', 16, 1)
    RETURN
  END
END;

EXEC Sp_CreateAccount
    @customer_id = '1ea5ec60-3f36-4896-af24-13ee03bf06d9',
    @account_number = '93528392029',
    @account_type = 'savings',
    @Balance = 900.89;

SELECT * FROM customers
WHERE customer_id = '1ea5ec60-3f36-4896-af24-13ee03bf06d9';

--Nomor 3
--Procedure sp_MakeTransaction untuk menambahkan transaksi baru
CREATE PROCEDURE sp_MakeTransaction 
	@account_id CHAR(36),
	@transaction_type_id INT,
	@amount DECIMAL(18,2),
	@description varchar(50),
	@reference_account CHAR(36)
AS
BEGIN 
	IF @amount <= (SELECT balance FROM accounts WHERE account_id = @account_id)
	BEGIN
		INSERT INTO transactions (account_id, transaction_type_id, amount, description, reference_account)
		VALUES(@account_id, @transaction_type_id, @amount, @description, @reference_account);
	END
END;

EXEC sp_MakeTransaction
	@account_id = 'f9341b55-2686-40af-9e1b-2986672efd92',
	@transaction_type_id = 2,
	@amount = 1000.00,
	@description = 'lorem ipsum dolor',
	@reference_account = 'd4f9b85e-4f3f-446a-a556-5d4a4ed5a667';

--Nomor 4
--Procedure sp_GetCustomerSummary untuk menampilkan ringkasan data customer berdasarkan customer_id
CREATE PROCEDURE sp_GetCustomerSummary
    @CustomerID CHAR(36)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        COUNT(DISTINCT a.account_id) AS total_accounts,
        ISNULL(SUM(a.balance), 0) AS total_balance,
        COUNT(DISTINCT l.loan_id) AS active_loans,
        ISNULL(SUM(l.loan_amount), 0) AS total_active_loan_amount
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id AND l.status = 'active'
    WHERE c.customer_id = @CustomerID
    GROUP BY c.first_name, c.last_name;
END;

EXEC sp_GetCustomerSummary '9d78736f-df51-4622-9cb1-c4db88dca2d0';

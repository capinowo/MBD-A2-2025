USE BANKDB;
GO

-- NOMOR 1
CREATE PROCEDURE sp_CreateCustomer
	@first_name VARCHAR(50),
	@last_name VARCHAR(50),
	@email VARCHAR(50),
	@phone_number VARCHAR(20),
	@address VARCHAR(255)
AS
BEGIN
	INSERT INTO customers(first_name, last_name, email, phone_number, address) 
	VALUES(@first_name, @last_name, @email, @phone_number, @address);
END;
GO

EXEC sp_CreateCustomer
	@first_name = 'Megan',
	@last_name = 'Kaith',
	@email = 'meghan123@yahoo.com',
	@phone_number = '(770) 678-9182',
	@address = '11121 Bentwood Lane, Austin, Texas, United States, 78778';
GO

select * from customers
where first_name = 'Megan';
GO

-- NOMOR 2
CREATE PROCEDURE sp_CreateAccount
    @p_customer_id VARCHAR(36),
    @p_account_number VARCHAR(20),
    @p_account_type VARCHAR(20),
    @p_balance DECIMAL(15,2)
AS
BEGIN
    -- Validasi apakah customer_id ada di tabel customers
    IF EXISTS (SELECT 1 FROM customers WHERE customer_id = @p_customer_id)
    BEGIN
        INSERT INTO accounts (account_number, customer_id, account_type, balance)
        VALUES (@p_account_number, @p_customer_id, @p_account_type, @p_balance);
    END
    ELSE
    BEGIN
        RAISERROR('Customer ID tidak ditemukan dalam tabel customers.', 16, 1);
    END
END
GO

EXEC sp_CreateAccount 
    @p_customer_id = 'a9de1fc5-3ba9-4088-8ee6-5a75104f2c7d',
    @p_account_number = '1234567890',
    @p_account_type = 'Savings',
    @p_balance = 1000.00;
GO

SELECT * FROM customers
WHERE customer_id = 'a9de1fc5-3ba9-4088-8ee6-5a75104f2c7d';
GO

-- NOMOR 3
CREATE PROCEDURE sp_MakeTransaction (
	@IdAkun CHAR(36),
	@JenisTransaksi INT,
	@jumlahUang DECIMAL(18,2),
	@description VARCHAR(500),
	@reference_account CHAR(36) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @BalanceTerknini DECIMAL(18,2);

	SELECT @BalanceTerknini = balance
	FROM dbo.accounts
	WHERE account_id = @IdAkun;

	IF @JenisTransaksi = 2 AND @jumlahUang > @BalanceTerknini
	BEGIN
		RAISERROR('Saldo tidak mencukupi untuk transfer.', 16, 1);
		RETURN;
	END

	INSERT INTO dbo.transactions(transaction_id, account_id, amount, description, reference_account)
	VALUES (@IdAkun, @JenisTransaksi, @JumlahUang, @description, @reference_account);

END;
GO

EXEC sp_MakeTransaction
	@IdAkun = '318c43bf-9511-4030-bd13-81a47a4b8cac',
	@JenisTransaksi = 2,
	@jumlahUang = 8000.00,
	@description = "Transfer pembelian baju",
	@reference_account = NULL;
GO

-- NOMOR 4
CREATE PROCEDURE sp_GetCustomerSummary
    @customer_id VARCHAR(36)
AS
BEGIN
    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        COUNT(DISTINCT a.account_id) AS total_accounts,
        SUM(a.balance) AS total_balance,
        COUNT(DISTINCT l.loan_id) AS active_loans,
        SUM(l.loan_amount) AS total_loan_amount
    FROM dbo.customers c
    LEFT JOIN dbo.accounts a ON a.customer_id = c.customer_id
    LEFT JOIN dbo.loans l ON l.customer_id = c.customer_id AND l.status = 'active'
    WHERE c.customer_id = @customer_id
    GROUP BY c.first_name, c.last_name;
END;
GO

EXEC sp_GetCustomerSummary @customer_id = 'a9de1fc5-3ba9-4088-8ee6-5a75104f2c7d';
GO
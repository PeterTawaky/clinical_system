CREATE TABLE branches (
    branch_id INT IDENTITY(1,1) PRIMARY KEY,
    branch_name NVARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE doctors (
    doctor_id INT IDENTITY(1,1) PRIMARY KEY,
    doctor_name NVARCHAR(100) NOT NULL,
    specialty NVARCHAR(100) NOT NULL,
    doctor_phone_number NVARCHAR(30) NOT NULL,
    doctor_balance DECIMAL(30,3),

    CONSTRAINT UQ_doctors_name_phone UNIQUE (doctor_name, doctor_phone_number)
);

CREATE TABLE doctor_branches (
    doctor_id INT NOT NULL,
    branch_id INT NOT NULL,
    PRIMARY KEY (doctor_id, branch_id),

    CONSTRAINT FK_doctor_branches_doctors
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON DELETE CASCADE,

    CONSTRAINT FK_doctor_branches_branches
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
	    ON DELETE CASCADE
);

CREATE TABLE patients (
    patient_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_name NVARCHAR(100) NOT NULL,
    phone NVARCHAR(20) NOT NULL,
    branch_id INT NULL,
    birth_date DATE NULL,

    CONSTRAINT FK_patients_branches
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);


SELECT
    d.doctor_id,
    d.doctor_name,
    d.specialty,
    STRING_AGG(b.branch_name, ', ') AS branches
FROM doctors d
LEFT JOIN doctor_branches db ON d.doctor_id = db.doctor_id
LEFT JOIN branches b ON db.branch_id = b.branch_id
GROUP BY d.doctor_id, d.doctor_name, d.specialty
ORDER BY d.doctor_id;

-- =============================================
-- Doctor Schedules
-- =============================================

CREATE TABLE doctor_schedules (
    schedule_id INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id INT NOT NULL,

    day_of_week NVARCHAR(20) NOT NULL,

    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    branch_id INT NULL,

    is_active BIT DEFAULT 1,

    CONSTRAINT FK_doctor_schedules_doctors
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
        ON DELETE CASCADE,

    CONSTRAINT FK_doctor_schedules_branches
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
        ON DELETE CASCADE
);

-- Migration (run on existing DB to replace branch text column with branch_id FK):
-- ALTER TABLE doctor_schedules DROP COLUMN branch;
-- ALTER TABLE doctor_schedules ADD branch_id INT NULL;
-- ALTER TABLE doctor_schedules ADD CONSTRAINT FK_doctor_schedules_branches
--     FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE CASCADE;

SELECT
    d.doctor_name,
    d.specialty,
    s.day_of_week,
    s.start_time,
    s.end_time
FROM
    doctors d
JOIN
    doctor_schedules s ON d.doctor_id = s.doctor_id
WHERE
    s.is_active = 1;


-- =============================================
-- Doctor Services
-- =============================================

CREATE TABLE doctor_services (
    service_id INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id INT NOT NULL,
    service_name NVARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    doctor_commission_percentage DECIMAL(5,2) NOT NULL DEFAULT 70.00, 
    
    CONSTRAINT FK_doctor_services_doctors
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON DELETE CASCADE
);

-- =============================================
-- Examinations
-- =============================================

CREATE TABLE examinations (
    exam_id INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id INT NOT NULL,
    patient_id INT NOT NULL,
    service_id INT NOT NULL,
    branch_id INT NOT NULL,

    exam_date DATETIME NOT NULL,
    exam_number NVARCHAR(50) NOT NULL,
    status NVARCHAR(20) NOT NULL ,  -- مؤقت / مؤكد / ملغي

    CONSTRAINT FK_examinations_doctors
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON DELETE CASCADE,

    CONSTRAINT FK_examinations_patients
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),

    CONSTRAINT FK_examinations_services
        FOREIGN KEY (service_id) REFERENCES doctor_services(service_id),

    CONSTRAINT FK_examinations_branches
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- Migration (run on existing DB to add branch_id to examinations):
-- ALTER TABLE examinations ADD branch_id INT NULL;
-- UPDATE examinations SET branch_id = 1;  -- set a default branch before enforcing NOT NULL
-- ALTER TABLE examinations ALTER COLUMN branch_id INT NOT NULL;
-- ALTER TABLE examinations ADD CONSTRAINT FK_examinations_branches
--     FOREIGN KEY (branch_id) REFERENCES branches(branch_id);

-- =============================================
-- Cleanup (run to reset)
-- =============================================

drop table examinations
drop table doctor_services
drop table doctor_schedules
drop table doctor_branches
drop table doctors
drop table branches
drop table patients

create table system_users(
	 username nvarchar(30) primary key,
	 role nvarchar(30) not null,
	 password nvarchar(50) not null,
	 createdat date DEFAULT SYSDATETIME()
);
insert into system_users (username, role, password)
values
	('tawaky','manager','tawaky');
	
	
create table actions_history(
	 action_id INT IDENTITY(1,1) PRIMARY KEY,
	 username nvarchar(30) not null,
	 action_description nvarchar(255) not null,
	 action_date DATETIME DEFAULT SYSDATETIME(),

	 CONSTRAINT FK_actions_history_system_users
	     FOREIGN KEY (username) REFERENCES system_users(username)
	     ON DELETE CASCADE
)


-- =============================================
-- تصنيفات المصاريف
-- =============================================
CREATE TABLE expense_categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name NVARCHAR(100) NOT NULL UNIQUE
);
INSERT INTO expense_categories (category_name)
VALUES
    (N'زيارات'),
    (N'فواتير'),
    (N'مشتريات');

drop table purchases
drop table treasury
drop table purchases_lines
drop table invoices
drop table debts
-- =============================================
-- Purchases
-- =============================================
CREATE TABLE purchases (
    purchase_id   INT IDENTITY(1,1) PRIMARY KEY,
    created_date  DATETIME         NOT NULL DEFAULT SYSDATETIME(),
    username      NVARCHAR(30)     NOT NULL,
    description   NVARCHAR(255)    NULL,
    category_id   INT              NOT NULL,
    status        NVARCHAR(20)     NOT NULL,   -- مديونية / تم السداد
    branch_id     INT              NOT NULL,

    CONSTRAINT FK_purchases_system_users
        FOREIGN KEY (username)    REFERENCES system_users(username),

    CONSTRAINT FK_purchases_categories
        FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),

    CONSTRAINT FK_purchases_branches
        FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),

    CONSTRAINT CHK_purchases_status
        CHECK (status IN (N'مديونية', N'تم السداد'))
);

-- =============================================
-- Purchases Lines
-- =============================================
CREATE TABLE purchases_lines (
    line_id     INT IDENTITY(1,1) PRIMARY KEY,
    purchase_id INT              NOT NULL,
    name        NVARCHAR(100)    NOT NULL,
    price       DECIMAL(18,3)    NOT NULL,
    quantity    DECIMAL(18,3)    NOT NULL,
    total       AS (quantity * price) PERSISTED,

    CONSTRAINT FK_purchases_lines_purchases
        FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id)
        ON DELETE CASCADE
);

-- =============================================
-- Debts
-- =============================================
-- Treasury
-- =============================================
CREATE TABLE treasury (
    treasury_id      INT IDENTITY(1,1) PRIMARY KEY,
    creation_date    DATETIME         NOT NULL DEFAULT SYSDATETIME(),
    amount           DECIMAL(18,3)    NOT NULL,
    transaction_type NVARCHAR(10)     NOT NULL,   -- دخل / خرج
    username         NVARCHAR(30)     NOT NULL,
    category_id      INT              NOT NULL,
    branch_id        INT              NOT NULL,

    CONSTRAINT FK_treasury_system_users
        FOREIGN KEY (username)    REFERENCES system_users(username),

    CONSTRAINT FK_treasury_categories
        FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),

    CONSTRAINT FK_treasury_branches
        FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),

    CONSTRAINT CHK_treasury_type
        CHECK (transaction_type IN (N'دخل', N'خرج'))
);

-- =============================================
-- Invoices
-- =============================================
CREATE TABLE invoices (
    invoice_id   INT IDENTITY(1,1) PRIMARY KEY,
    created_date DATETIME         NOT NULL DEFAULT SYSDATETIME(),
    username     NVARCHAR(30)     NOT NULL,
    name         NVARCHAR(100)    NOT NULL,
    price        DECIMAL(18,3)    NOT NULL,
    branch_id    INT              NOT NULL,
    description  NVARCHAR(255)    NULL,
    status       NVARCHAR(20)     NOT NULL,   -- مديونية / تم السداد
    category_id  INT              NOT NULL,

    CONSTRAINT FK_invoices_system_users
        FOREIGN KEY (username)    REFERENCES system_users(username),

    CONSTRAINT FK_invoices_branches
        FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),

    CONSTRAINT FK_invoices_categories
        FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),

    CONSTRAINT CHK_invoices_status
        CHECK (status IN (N'مديونية', N'تم السداد'))
);

-- =============================================
-- Debts
-- =============================================
CREATE TABLE debts (
    debt_id       INT IDENTITY(1,1) PRIMARY KEY,
    creation_date DATETIME         NOT NULL DEFAULT SYSDATETIME(),
    payment_date  DATETIME         NOT NULL DEFAULT SYSDATETIME(),
    amount        DECIMAL(18,3)    NOT NULL,
    status        NVARCHAR(20)     NOT NULL,   -- مديونية / تم السداد
    username      NVARCHAR(30)     NOT NULL,
    category_id   INT              NOT NULL,
    branch_id     INT              NOT NULL,

    -- Exactly one source FK will be set; the other two must be NULL
    purchase_id   INT              NULL,
    exam_id       INT              NULL,
    invoice_id    INT              NULL,

    CONSTRAINT FK_debts_system_users
        FOREIGN KEY (username)    REFERENCES system_users(username),

    CONSTRAINT FK_debts_categories
        FOREIGN KEY (category_id) REFERENCES expense_categories(category_id),

    CONSTRAINT FK_debts_branches
        FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),

    CONSTRAINT FK_debts_purchases
        FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id)
        ON DELETE SET NULL,

    CONSTRAINT FK_debts_examinations
        FOREIGN KEY (exam_id)     REFERENCES examinations(exam_id)
        ON DELETE SET NULL,

    CONSTRAINT FK_debts_invoices
        FOREIGN KEY (invoice_id)  REFERENCES invoices(invoice_id)
        ON DELETE SET NULL,

    CONSTRAINT CHK_debts_status
        CHECK (status IN (N'مديونية', N'تم السداد')),

    -- Exactly one source must be non-NULL
    CONSTRAINT CHK_debts_single_source CHECK (
        (purchase_id IS NOT NULL AND exam_id IS NULL    AND invoice_id IS NULL) OR
        (purchase_id IS NULL    AND exam_id IS NOT NULL AND invoice_id IS NULL) OR
        (purchase_id IS NULL    AND exam_id IS NULL     AND invoice_id IS NOT NULL)
    )
);


select * from patients
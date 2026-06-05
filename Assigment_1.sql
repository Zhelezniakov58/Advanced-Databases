DROP TABLE IF EXISTS AUDIT_LOG                CASCADE;
DROP TABLE IF EXISTS FRAUD_ALERTS             CASCADE;
DROP TABLE IF EXISTS FRAUD_RULES              CASCADE;
DROP TABLE IF EXISTS TRANSACTION_STATUS_HISTORY CASCADE;
DROP TABLE IF EXISTS TRANSACTIONS             CASCADE;
DROP TABLE IF EXISTS CARDS                    CASCADE;
DROP TABLE IF EXISTS ACCOUNTS                 CASCADE;
DROP TABLE IF EXISTS CUSTOMERS                CASCADE;

CREATE TABLE CUSTOMERS (
    customer_id  BIGSERIAL    PRIMARY KEY,
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    birth_date   DATE         NOT NULL,
    country_code CHAR(2)      NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE ACCOUNTS (
    account_id     BIGSERIAL      PRIMARY KEY,
    customer_id    BIGINT         NOT NULL REFERENCES CUSTOMERS(customer_id),
    account_number VARCHAR(20)    NOT NULL UNIQUE,
    currency       CHAR(3)        NOT NULL check (currency IN ('UAH', 'USD', 'EUR')),
    balance        NUMERIC(18,2)  NOT NULL DEFAULT 0.00 check (balance >= 0),
    status         VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE'
                       CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED')),
    opened_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE CARDS (
    card_id          BIGSERIAL    PRIMARY KEY,
    account_id       BIGINT       NOT NULL REFERENCES ACCOUNTS(account_id),
    card_number_hash VARCHAR(128)  NOT NULL UNIQUE,
    card_type        VARCHAR(20)  NOT NULL CHECK (card_type IN ('DEBIT','CREDIT','PREPAID')),
    status           VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
                         CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED')),
    expiration_date  DATE         NOT NULL
);

CREATE TABLE TRANSACTIONS (
    transaction_id   BIGSERIAL      PRIMARY KEY,
    account_id       BIGINT         NOT NULL REFERENCES ACCOUNTS(account_id),
    card_id          BIGINT         REFERENCES CARDS(card_id),
    amount           NUMERIC(18,2)  NOT NULL check (amount > 0),
    currency         CHAR(3)        NOT NULL check (currency in ('UAH', 'USD', 'EUR')),
    merchant_category VARCHAR(50),
    merchant_country  CHAR(2),
    status           VARCHAR(20)    NOT NULL DEFAULT 'PENDING'
                         CHECK (status IN ('PENDING','COMPLETED','FAILED','REVERSED','FLAGGED')),
    risk_score       INT            NOT NULL DEFAULT 0 CHECK (risk_score BETWEEN 0 AND 100),
    transaction_at   TIMESTAMPTZ    NOT NULL,
    created_at       TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE TRANSACTION_STATUS_HISTORY (
    history_id     BIGSERIAL    PRIMARY KEY,
    transaction_id BIGINT       NOT NULL REFERENCES TRANSACTIONS(transaction_id),
    old_status     VARCHAR(20),
    new_status     VARCHAR(20)  NOT NULL,
    changed_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    changed_by     VARCHAR(100) NOT NULL
);

CREATE TABLE FRAUD_RULES (
    rule_id         BIGSERIAL    PRIMARY KEY,
    rule_name       VARCHAR(100) NOT NULL,
    rule_type       VARCHAR(50)  NOT NULL,
    threshold_value INT          NOT NULL,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE FRAUD_ALERTS (
    alert_id       BIGSERIAL    PRIMARY KEY,
    transaction_id BIGINT       NOT NULL REFERENCES TRANSACTIONS(transaction_id),
    rule_id        BIGINT       NOT NULL REFERENCES FRAUD_RULES(rule_id),
    reason         TEXT         NOT NULL,
    risk_score     INT          NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
    alert_status   VARCHAR(20)  NOT NULL DEFAULT 'OPEN'
                       CHECK (alert_status IN ('OPEN','UNDER_REVIEW','RESOLVED','FALSE_POSITIVE')),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE AUDIT_LOG (
    audit_id    BIGSERIAL    PRIMARY KEY,
    customer_id BIGINT       REFERENCES CUSTOMERS(customer_id),
    table_name  VARCHAR(100) NOT NULL,
    operation   VARCHAR(10)  NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
    old_value   JSONB,
    new_value   JSONB,
    changed_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

--  CUSTOMERS  (20 rows)
-- ─────────────────────────────────────────────
-- ─────────────────────────────────────────────
INSERT INTO CUSTOMERS (first_name, last_name, email, birth_date, country_code, created_at, is_active) VALUES
('Olena',    'Kovalenko',   'olena.kovalenko@email.com',    '1988-03-12', 'UA', '2021-01-15 09:23:00+00', TRUE),
('Mykola',   'Bondarenko',  'mykola.bondarenko@email.com',  '1990-07-04', 'UA', '2021-02-20 11:05:00+00', TRUE),
('Iryna',    'Shevchenko',  'iryna.shevchenko@email.com',   '1978-11-22', 'UA', '2021-03-08 14:30:00+00', TRUE),
('Dmytro',   'Lysenko',     'dmytro.lysenko@email.com',     '1995-05-18', 'UA', '2021-04-01 08:00:00+00', TRUE),
('Natalia',  'Melnyk',      'natalia.melnyk@email.com',     '1985-09-30', 'UA', '2021-05-17 16:45:00+00', TRUE),
('Andriy',   'Petrenko',    'andriy.petrenko@email.com',    '1982-01-07', 'UA', '2021-06-22 10:10:00+00', TRUE),
('Tetyana',  'Savchenko',   'tetyana.savchenko@email.com',  '1993-12-03', 'UA', '2021-07-11 13:20:00+00', TRUE),
('Vasyl',    'Tkachenko',   'vasyl.tkachenko@email.com',    '1987-06-25', 'UA', '2021-08-05 07:55:00+00', FALSE),
('Oksana',   'Moroz',       'oksana.moroz@email.com',       '1975-04-14', 'UA', '2021-09-18 12:00:00+00', TRUE),
('Serhiy',   'Kravchenko',  'serhiy.kravchenko@email.com',  '1991-08-09', 'UA', '2021-10-30 09:40:00+00', TRUE),
('Larysa',   'Rudenko',     'larysa.rudenko@email.com',     '1983-02-28', 'UA', '2022-01-03 15:15:00+00', TRUE),
('Yurii',    'Savenko',     'yurii.savenko@email.com',      '1997-10-11', 'UA', '2022-02-14 11:30:00+00', TRUE),
('Halyna',   'Kovalchuk',   'halyna.kovalchuk@email.com',   '1980-07-19', 'UA', '2022-03-22 08:20:00+00', TRUE),
('Bohdan',   'Marchenko',   'bohdan.marchenko@email.com',   '1994-03-05', 'UA', '2022-04-09 10:50:00+00', TRUE),
('Svitlana', 'Hrytsenko',   'svitlana.hrytsenko@email.com', '1986-11-16', 'UA', '2022-05-27 14:05:00+00', FALSE),
('Pavlo',    'Ponomarenko', 'pavlo.ponomarenko@email.com',  '1992-09-23', 'UA', '2022-06-15 09:00:00+00', TRUE),
('Viktoria', 'Davydenko',   'viktoria.davydenko@email.com', '1979-06-01', 'UA', '2022-07-08 16:30:00+00', TRUE),
('Roman',    'Ivanenko',    'roman.ivanenko@email.com',     '1989-01-27', 'UA', '2022-08-19 11:45:00+00', TRUE),
('Alina',    'Karpenko',    'alina.karpenko@email.com',     '1996-05-08', 'UA', '2022-09-30 13:00:00+00', TRUE),
('Taras',    'Fedorenko',   'taras.fedorenko@email.com',    '1984-12-15', 'UA', '2022-10-12 10:25:00+00', TRUE);

-- ─────────────────────────────────────────────
--  ACCOUNTS  (25 rows)
--  currency IN ('UAH','USD','EUR')
--  status   IN ('PENDING','APPROVED','DECLINED','FLAGGED')
--  balance  >= 0
-- ─────────────────────────────────────────────
INSERT INTO ACCOUNTS (customer_id, account_number, currency, balance, status, opened_at) VALUES
(1,  'UA-ACC-000001', 'UAH', 124500.75,  'APPROVED', '2021-01-16 10:00:00+00'),
(1,  'UA-ACC-000002', 'USD',   3200.00,  'APPROVED', '2022-03-01 10:00:00+00'),
(2,  'UA-ACC-000003', 'UAH',  89000.00,  'APPROVED', '2021-02-21 10:00:00+00'),
(3,  'UA-ACC-000004', 'EUR',   5500.50,  'APPROVED', '2021-03-09 10:00:00+00'),
(4,  'UA-ACC-000005', 'USD',    750.00,  'APPROVED', '2021-04-02 10:00:00+00'),
(5,  'UA-ACC-000006', 'UAH',  89002.25,  'APPROVED', '2021-05-18 10:00:00+00'),
(6,  'UA-ACC-000007', 'USD',  42000.00,  'APPROVED', '2021-06-23 10:00:00+00'),
(7,  'UA-ACC-000008', 'EUR',   6780.30,  'APPROVED', '2021-07-12 10:00:00+00'),
(8,  'UA-ACC-000009', 'UAH',      0.00,  'FLAGGED',  '2021-08-06 10:00:00+00'),
(9,  'UA-ACC-000010', 'EUR',  14200.00,  'APPROVED', '2021-09-19 10:00:00+00'),
(10, 'UA-ACC-000011', 'EUR',   3100.60,  'APPROVED', '2021-10-31 10:00:00+00'),
(11, 'UA-ACC-000012', 'UAH',  78000.00,  'APPROVED', '2022-01-04 10:00:00+00'),
(12, 'UA-ACC-000013', 'UAH',  92500.00,  'APPROVED', '2022-02-15 10:00:00+00'),
(13, 'UA-ACC-000014', 'UAH', 113007.50,  'APPROVED', '2022-03-23 10:00:00+00'),
(14, 'UA-ACC-000015', 'USD',   2200.00,  'APPROVED', '2022-04-10 10:00:00+00'),
(15, 'UA-ACC-000016', 'EUR',      0.00,  'DECLINED', '2022-05-28 10:00:00+00'),
(16, 'UA-ACC-000017', 'USD',   9500.00,  'APPROVED', '2022-06-16 10:00:00+00'),
(17, 'UA-ACC-000018', 'EUR',  22500.00,  'APPROVED', '2022-07-09 10:00:00+00'),
(18, 'UA-ACC-000019', 'UAH',  34000.00,  'APPROVED', '2022-08-20 10:00:00+00'),
(19, 'UA-ACC-000020', 'UAH',  15500.00,  'APPROVED', '2022-10-01 10:00:00+00'),
(20, 'UA-ACC-000021', 'USD',   7800.50,  'APPROVED', '2022-10-13 10:00:00+00'),
(5,  'UA-ACC-000022', 'EUR',   1500.00,  'PENDING',  '2023-01-10 10:00:00+00'),
(12, 'UA-ACC-000023', 'USD',   3300.00,  'APPROVED', '2023-02-05 10:00:00+00'),
(16, 'UA-ACC-000024', 'UAH',  88000.00,  'APPROVED', '2023-03-20 10:00:00+00'),
(20, 'UA-ACC-000025', 'EUR',   5100.00,  'FLAGGED',  '2023-04-15 10:00:00+00');

-- ─────────────────────────────────────────────
--  CARDS  (30 rows)
--  status IN ('PENDING','APPROVED','DECLINED','FLAGGED')
-- ─────────────────────────────────────────────
INSERT INTO CARDS (account_id, card_number_hash, card_type, status, expiration_date) VALUES
(1,  sha256('4111111111111111'::bytea)::text, 'DEBIT',   'APPROVED', '2027-03-31'),
(1,  sha256('4111111111112222'::bytea)::text, 'CREDIT',  'APPROVED', '2026-11-30'),
(2,  sha256('4222222222221111'::bytea)::text, 'DEBIT',   'APPROVED', '2028-01-31'),
(3,  sha256('4333333333331111'::bytea)::text, 'CREDIT',  'FLAGGED',  '2026-06-30'),
(4,  sha256('4444444444441111'::bytea)::text, 'DEBIT',   'APPROVED', '2027-09-30'),
(5,  sha256('4555555555551111'::bytea)::text, 'PREPAID', 'APPROVED', '2025-12-31'),
(6,  sha256('4666666666661111'::bytea)::text, 'DEBIT',   'APPROVED', '2027-05-31'),
(7,  sha256('4777777777771111'::bytea)::text, 'CREDIT',  'APPROVED', '2026-08-31'),
(8,  sha256('4888888888881111'::bytea)::text, 'DEBIT',   'APPROVED', '2028-02-28'),
(9,  sha256('4999999999991111'::bytea)::text, 'DEBIT',   'DECLINED', '2024-12-31'),
(10, sha256('5010101010101111'::bytea)::text, 'CREDIT',  'APPROVED', '2027-07-31'),
(11, sha256('5011111111111111'::bytea)::text, 'DEBIT',   'APPROVED', '2028-04-30'),
(12, sha256('5012121212121111'::bytea)::text, 'CREDIT',  'APPROVED', '2027-10-31'),
(13, sha256('5013131313131111'::bytea)::text, 'DEBIT',   'APPROVED', '2026-12-31'),
(14, sha256('5014141414141111'::bytea)::text, 'PREPAID', 'APPROVED', '2026-03-31'),
(15, sha256('5015151515151111'::bytea)::text, 'DEBIT',   'APPROVED', '2027-06-30'),
(16, sha256('5016161616161111'::bytea)::text, 'CREDIT',  'FLAGGED',  '2026-09-30'),
(17, sha256('5017171717171111'::bytea)::text, 'DEBIT',   'APPROVED', '2028-03-31'),
(18, sha256('5018181818181111'::bytea)::text, 'CREDIT',  'APPROVED', '2027-01-31'),
(19, sha256('5019191919191111'::bytea)::text, 'DEBIT',   'DECLINED', '2024-06-30'),
(20, sha256('5020202020201111'::bytea)::text, 'CREDIT',  'APPROVED', '2027-11-30'),
(21, sha256('5021212121211111'::bytea)::text, 'DEBIT',   'APPROVED', '2028-05-31'),
(22, sha256('5022222222221111'::bytea)::text, 'PREPAID', 'PENDING',  '2026-07-31'),
(23, sha256('5023232323231111'::bytea)::text, 'CREDIT',  'APPROVED', '2027-04-30'),
(24, sha256('5024242424241111'::bytea)::text, 'DEBIT',   'APPROVED', '2028-06-30'),
(25, sha256('5025252525251111'::bytea)::text, 'CREDIT',  'FLAGGED',  '2027-08-31'),
(1,  sha256('5026262626261111'::bytea)::text, 'PREPAID', 'DECLINED', '2024-03-31'),
(6,  sha256('5027272727271111'::bytea)::text, 'CREDIT',  'APPROVED', '2028-07-31'),
(10, sha256('5028282828281111'::bytea)::text, 'DEBIT',   'FLAGGED',  '2026-10-31'),
(16, sha256('5029292929291111'::bytea)::text, 'PREPAID', 'APPROVED', '2027-02-28');

-- ─────────────────────────────────────────────
--  TRANSACTIONS  (40 rows)
--  currency IN ('UAH','USD','EUR') | amount > 0
-- ─────────────────────────────────────────────
INSERT INTO TRANSACTIONS
    (account_id, card_id, amount, currency, merchant_category, merchant_country,
     status, risk_score, transaction_at, created_at)
VALUES
-- Normal completed
(1,  1,   4520.50,  'UAH', 'GROCERY',        'UA', 'COMPLETED', 5,  '2024-01-05 08:30:00+00', '2024-01-05 08:30:01+00'),
(1,  2,  32999.00,  'UAH', 'ELECTRONICS',    'UA', 'COMPLETED', 12, '2024-01-10 15:20:00+00', '2024-01-10 15:20:01+00'),
(2,  3,   8700.00,  'UAH', 'RESTAURANT',     'UA', 'COMPLETED', 3,  '2024-01-12 19:00:00+00', '2024-01-12 19:00:01+00'),
(3,  4,    250.00,  'EUR', 'TRAVEL',         'DE', 'COMPLETED', 18, '2024-01-15 10:45:00+00', '2024-01-15 10:45:01+00'),
(4,  5,     35.00,  'USD', 'GROCERY',        'UA', 'COMPLETED', 6,  '2024-01-18 12:00:00+00', '2024-01-18 12:00:01+00'),
(5,  6,    780.00,  'USD', 'TRAVEL',         'PL', 'COMPLETED', 22, '2024-01-20 09:15:00+00', '2024-01-20 09:15:01+00'),
(6,  7,   3200.00,  'USD', 'PHARMACY',       'UA', 'COMPLETED', 14, '2024-01-22 14:30:00+00', '2024-01-22 14:30:01+00'),
(7,  8,    420.00,  'EUR', 'RESTAURANT',     'UA', 'COMPLETED', 4,  '2024-01-25 20:00:00+00', '2024-01-25 20:00:01+00'),
(9,  10,   180.00,  'EUR', 'CLOTHING',       'PL', 'COMPLETED', 9,  '2024-02-01 11:20:00+00', '2024-02-01 11:20:01+00'),
(10, 11,    55.50,  'EUR', 'GROCERY',        'UA', 'COMPLETED', 3,  '2024-02-03 08:50:00+00', '2024-02-03 08:50:01+00'),
-- Flagged / high-risk
(1,  1,  85000.00,  'UAH', 'GAMBLING',       'MT', 'FLAGGED',   82, '2024-02-05 03:12:00+00', '2024-02-05 03:12:01+00'),
(5,  6,   3500.00,  'USD', 'CRYPTOCURRENCY', 'UA', 'FLAGGED',   91, '2024-02-07 01:45:00+00', '2024-02-07 01:45:01+00'),
(16, 17,  2100.00,  'USD', 'WIRE_TRANSFER',  'CY', 'FLAGGED',   78, '2024-02-09 02:30:00+00', '2024-02-09 02:30:01+00'),
(6,  7,  12500.00,  'USD', 'LUXURY_GOODS',   'AE', 'FLAGGED',   88, '2024-02-10 23:50:00+00', '2024-02-10 23:50:01+00'),
(20, 21, 74000.00,  'UAH', 'GAMBLING',       'MT', 'FLAGGED',   74, '2024-02-12 04:10:00+00', '2024-02-12 04:10:01+00'),
-- Failed
(4,  5,    200.00,  'USD', 'ATM',            'UA', 'FAILED',    15, '2024-02-14 10:00:00+00', '2024-02-14 10:00:01+00'),
(8,  9,   9500.00,  'UAH', 'ATM',            'UA', 'FAILED',    20, '2024-02-14 11:00:00+00', '2024-02-14 11:00:01+00'),
(3,  4,     90.00,  'EUR', 'TRANSPORT',      'UA', 'FAILED',    8,  '2024-02-15 07:30:00+00', '2024-02-15 07:30:01+00'),
-- Reversed (two-step)
(2,  3,  45000.00,  'UAH', 'TRAVEL',         'PL', 'REVERSED',  45, '2024-02-18 09:00:00+00', '2024-02-18 09:00:01+00'),
(9,  10,   320.00,  'EUR', 'ELECTRONICS',    'DE', 'REVERSED',  30, '2024-02-20 16:00:00+00', '2024-02-20 16:00:01+00'),
-- More normal activity
(11, 12, 12450.00,  'UAH', 'GROCERY',        'UA', 'COMPLETED', 5,  '2024-03-01 09:10:00+00', '2024-03-01 09:10:01+00'),
(12, 13,  8320.00,  'UAH', 'CLOTHING',       'UA', 'COMPLETED', 7,  '2024-03-05 14:00:00+00', '2024-03-05 14:00:01+00'),
(13, 14,  6499.00,  'UAH', 'GROCERY',        'UA', 'COMPLETED', 4,  '2024-03-08 10:30:00+00', '2024-03-08 10:30:01+00'),
(14, 15,   150.00,  'USD', 'RESTAURANT',     'UA', 'COMPLETED', 6,  '2024-03-12 13:20:00+00', '2024-03-12 13:20:01+00'),
(17, 18,   600.00,  'EUR', 'TRAVEL',         'PL', 'COMPLETED', 14, '2024-03-15 08:00:00+00', '2024-03-15 08:00:01+00'),
(18, 19, 22300.00,  'UAH', 'GROCERY',        'UA', 'COMPLETED', 5,  '2024-03-18 11:45:00+00', '2024-03-18 11:45:01+00'),
(19, 20, 47200.00,  'UAH', 'ELECTRONICS',    'UA', 'COMPLETED', 18, '2024-03-20 15:30:00+00', '2024-03-20 15:30:01+00'),
(20, 21,  1200.00,  'UAH', 'GROCERY',        'UA', 'COMPLETED', 3,  '2024-03-22 08:45:00+00', '2024-03-22 08:45:01+00'),
-- Recent pending
(1,  1,   5525.00,  'UAH', 'GROCERY',        'UA', 'PENDING',   4,  '2026-05-29 09:00:00+00', '2026-05-29 09:00:01+00'),
(5,  6,    430.00,  'USD', 'TRAVEL',         'DE', 'PENDING',   21, '2026-05-29 10:30:00+00', '2026-05-29 10:30:01+00'),
(7,  8,    380.00,  'EUR', 'CLOTHING',       'UA', 'PENDING',   9,  '2026-05-29 11:15:00+00', '2026-05-29 11:15:01+00'),
(10, 11,    50.00,  'EUR', 'TRANSPORT',      'UA', 'PENDING',   6,  '2026-05-29 12:00:00+00', '2026-05-29 12:00:01+00'),
(16, 17,   980.00,  'USD', 'ELECTRONICS',    'UA', 'PENDING',   11, '2026-05-29 13:10:00+00', '2026-05-29 13:10:01+00'),
-- Additional
(22, 22,  7200.00,  'UAH', 'GROCERY',        'UA', 'COMPLETED', 5,  '2024-04-01 09:00:00+00', '2024-04-01 09:00:01+00'),
(23, 23,   750.00,  'USD', 'TRAVEL',         'PL', 'COMPLETED', 19, '2024-04-05 14:30:00+00', '2024-04-05 14:30:01+00'),
(24, 24,  4500.00,  'USD', 'LUXURY_GOODS',   'UA', 'FLAGGED',   85, '2024-04-08 02:00:00+00', '2024-04-08 02:00:01+00'),
(25, 25,   310.00,  'USD', 'RESTAURANT',     'UA', 'COMPLETED', 4,  '2024-04-10 20:00:00+00', '2024-04-10 20:00:01+00'),
(6,  28,   480.00,  'EUR', 'TRAVEL',         'FR', 'COMPLETED', 12, '2024-04-12 10:00:00+00', '2024-04-12 10:00:01+00'),
(10, 29,  2100.00,  'UAH', 'ELECTRONICS',    'UA', 'FLAGGED',   72, '2024-04-15 03:30:00+00', '2024-04-15 03:30:01+00'),
(16, 30,  4850.00,  'UAH', 'GROCERY',        'UA', 'COMPLETED', 3,  '2024-04-18 08:00:00+00', '2024-04-18 08:00:01+00');

-- ─────────────────────────────────────────────
--  TRANSACTION_STATUS_HISTORY  (23 rows)
-- ─────────────────────────────────────────────
INSERT INTO TRANSACTION_STATUS_HISTORY
    (transaction_id, old_status, new_status, changed_at, changed_by)
VALUES
(1,  'PENDING',   'COMPLETED', '2024-01-05 08:30:05+00', 'system:payment_processor'),
(2,  'PENDING',   'COMPLETED', '2024-01-10 15:20:05+00', 'system:payment_processor'),
(3,  'PENDING',   'COMPLETED', '2024-01-12 19:00:05+00', 'system:payment_processor'),
(4,  'PENDING',   'COMPLETED', '2024-01-15 10:45:05+00', 'system:payment_processor'),
(5,  'PENDING',   'COMPLETED', '2024-01-18 12:00:05+00', 'system:payment_processor'),
(6,  'PENDING',   'COMPLETED', '2024-01-20 09:15:05+00', 'system:payment_processor'),
(7,  'PENDING',   'COMPLETED', '2024-01-22 14:30:05+00', 'system:payment_processor'),
(8,  'PENDING',   'COMPLETED', '2024-01-25 20:00:05+00', 'system:payment_processor'),
(11, 'PENDING',   'FLAGGED',   '2024-02-05 03:12:10+00', 'system:fraud_engine'),
(12, 'PENDING',   'FLAGGED',   '2024-02-07 01:45:10+00', 'system:fraud_engine'),
(13, 'PENDING',   'FLAGGED',   '2024-02-09 02:30:10+00', 'system:fraud_engine'),
(14, 'PENDING',   'FLAGGED',   '2024-02-10 23:50:10+00', 'system:fraud_engine'),
(15, 'PENDING',   'FLAGGED',   '2024-02-12 04:10:10+00', 'system:fraud_engine'),
(16, 'PENDING',   'FAILED',    '2024-02-14 10:00:05+00', 'system:payment_processor'),
(17, 'PENDING',   'FAILED',    '2024-02-14 11:00:05+00', 'system:payment_processor'),
(18, 'PENDING',   'FAILED',    '2024-02-15 07:30:05+00', 'system:payment_processor'),
(19, 'PENDING',   'COMPLETED', '2024-02-18 09:00:05+00', 'system:payment_processor'),
(19, 'COMPLETED', 'REVERSED',  '2024-02-19 11:00:00+00', 'agent:cs_team'),
(20, 'PENDING',   'COMPLETED', '2024-02-20 16:00:05+00', 'system:payment_processor'),
(20, 'COMPLETED', 'REVERSED',  '2024-02-21 09:00:00+00', 'agent:cs_team'),
(36, 'PENDING',   'FLAGGED',   '2024-04-08 02:00:10+00', 'system:fraud_engine'),
(36, 'FLAGGED',   'COMPLETED', '2024-04-09 10:00:00+00', 'agent:fraud_team'),
(39, 'PENDING',   'FLAGGED',   '2024-04-15 03:30:10+00', 'system:fraud_engine');

-- ─────────────────────────────────────────────
--  FRAUD_RULES  (10 rows)
--  Thresholds calibrated for UAH-primary bank
-- ─────────────────────────────────────────────
INSERT INTO FRAUD_RULES (rule_name, rule_type, threshold_value, is_active) VALUES
('High Value Single Transaction',  'AMOUNT_THRESHOLD',  50000, TRUE),
('Rapid Succession Transactions',  'VELOCITY',          5,     TRUE),
('High Risk Country Transaction',  'GEO_RISK',          70,    TRUE),
('Late Night Large Transaction',   'TIME_AMOUNT',       30000, TRUE),
('Gambling Merchant Flag',         'MERCHANT_CATEGORY', 0,     TRUE),
('Cryptocurrency Purchase',        'MERCHANT_CATEGORY', 0,     TRUE),
('Card Not Present Threshold',     'CNP_AMOUNT',        10000, TRUE),
('Multiple Country in 24 Hours',   'GEO_VELOCITY',      2,     TRUE),
('Risk Score Threshold',           'RISK_SCORE',        75,    TRUE),
('Inactive Account Transaction',   'ACCOUNT_STATUS',    0,     FALSE);

-- ─────────────────────────────────────────────
--  FRAUD_ALERTS  (14 rows)
-- ─────────────────────────────────────────────
INSERT INTO FRAUD_ALERTS
    (transaction_id, rule_id, reason, risk_score, alert_status, created_at)
VALUES
(11, 4, 'Large UAH transaction at 03:12 AM exceeds late-night threshold of 30000 UAH',       82, 'RESOLVED',       '2024-02-05 03:12:12+00'),
(11, 5, 'Merchant category GAMBLING detected — flagged by policy',                            82, 'RESOLVED',       '2024-02-05 03:12:13+00'),
(12, 6, 'Cryptocurrency purchase flagged as high-risk merchant category',                     91, 'UNDER_REVIEW',   '2024-02-07 01:45:12+00'),
(12, 9, 'Risk score 91 exceeds configured threshold of 75',                                   91, 'UNDER_REVIEW',   '2024-02-07 01:45:13+00'),
(12, 3, 'Transaction originating from geo-risk country above defined threshold',              91, 'UNDER_REVIEW',   '2024-02-07 01:45:14+00'),
(13, 7, 'Wire transfer to CY flagged as high-value Card Not Present transaction',             78, 'OPEN',           '2024-02-09 02:30:12+00'),
(13, 4, 'Transaction at 02:30 AM exceeds late-night amount threshold',                        78, 'OPEN',           '2024-02-09 02:30:13+00'),
(14, 1, 'Single transaction of $12,500 USD exceeds high-value threshold',                     88, 'RESOLVED',       '2024-02-10 23:50:12+00'),
(14, 9, 'Risk score 88 exceeds configured threshold of 75',                                   88, 'RESOLVED',       '2024-02-10 23:50:13+00'),
(15, 5, 'Merchant category GAMBLING detected — marked false positive after manual review',    74, 'FALSE_POSITIVE', '2024-02-12 04:10:12+00'),
(36, 1, 'Single transaction of $4,500 USD approaching high-value threshold',                  85, 'RESOLVED',       '2024-04-08 02:00:12+00'),
(36, 4, 'Large transaction at 02:00 AM exceeds late-night threshold',                         85, 'RESOLVED',       '2024-04-08 02:00:13+00'),
(39, 8, 'Card used in multiple countries within a 24-hour window',                            72, 'OPEN',           '2024-04-15 03:30:12+00'),
(39, 9, 'Risk score 72 approaching configured threshold of 75',                               72, 'OPEN',           '2024-04-15 03:30:13+00');

-- ─────────────────────────────────────────────
--  AUDIT_LOG  (20 rows)
--  customer_id is nullable (system-level ops use NULL)
-- ─────────────────────────────────────────────
INSERT INTO AUDIT_LOG
    (customer_id, table_name, operation, old_value, new_value, changed_at)
VALUES
(1,    'CUSTOMERS',    'UPDATE',
       '{"email":"o.kovalenko@old.com","is_active":true}',
       '{"email":"olena.kovalenko@email.com","is_active":true}',
       '2021-06-10 10:00:00+00'),
(8,    'CUSTOMERS',    'UPDATE',
       '{"is_active":true}',
       '{"is_active":false}',
       '2022-11-01 09:00:00+00'),
(15,   'CUSTOMERS',    'UPDATE',
       '{"is_active":true}',
       '{"is_active":false}',
       '2023-03-15 14:00:00+00'),
(8,    'ACCOUNTS',     'UPDATE',
       '{"status":"APPROVED","balance":25000.00}',
       '{"status":"FLAGGED","balance":0.00}',
       '2022-11-01 09:05:00+00'),
(15,   'ACCOUNTS',     'UPDATE',
       '{"status":"APPROVED","balance":1200.50}',
       '{"status":"DECLINED","balance":0.00}',
       '2023-03-15 14:10:00+00'),
(3,    'CARDS',        'UPDATE',
       '{"status":"APPROVED"}',
       '{"status":"FLAGGED"}',
       '2024-01-20 11:30:00+00'),
(16,   'CARDS',        'UPDATE',
       '{"status":"APPROVED"}',
       '{"status":"FLAGGED"}',
       '2024-03-01 16:00:00+00'),
(10,   'CARDS',        'UPDATE',
       '{"status":"APPROVED"}',
       '{"status":"FLAGGED"}',
       '2024-04-16 08:00:00+00'),
(1,    'TRANSACTIONS', 'UPDATE',
       '{"status":"PENDING","risk_score":82}',
       '{"status":"FLAGGED","risk_score":82}',
       '2024-02-05 03:12:10+00'),
(5,    'TRANSACTIONS', 'UPDATE',
       '{"status":"PENDING","risk_score":91}',
       '{"status":"FLAGGED","risk_score":91}',
       '2024-02-07 01:45:10+00'),
(2,    'TRANSACTIONS', 'UPDATE',
       '{"status":"COMPLETED"}',
       '{"status":"REVERSED"}',
       '2024-02-19 11:00:00+00'),
(9,    'TRANSACTIONS', 'UPDATE',
       '{"status":"COMPLETED"}',
       '{"status":"REVERSED"}',
       '2024-02-21 09:00:00+00'),
(6,    'FRAUD_ALERTS', 'INSERT',
       NULL,
       '{"alert_id":8,"alert_status":"OPEN","risk_score":88}',
       '2024-02-10 23:50:12+00'),
(6,    'FRAUD_ALERTS', 'UPDATE',
       '{"alert_status":"OPEN"}',
       '{"alert_status":"RESOLVED"}',
       '2024-02-13 10:00:00+00'),
(1,    'FRAUD_ALERTS', 'UPDATE',
       '{"alert_status":"OPEN"}',
       '{"alert_status":"RESOLVED"}',
       '2024-02-06 09:30:00+00'),
(NULL, 'FRAUD_RULES',  'INSERT',
       NULL,
       '{"rule_id":10,"rule_name":"Inactive Account Transaction","is_active":false}',
       '2024-01-02 09:00:00+00'),
(NULL, 'FRAUD_RULES',  'UPDATE',
       '{"is_active":true}',
       '{"is_active":false}',
       '2023-12-01 08:00:00+00'),
(20,   'CUSTOMERS',    'UPDATE',
       '{"first_name":"Taras"}',
       '{"first_name":"Taras","country_code":"UA"}',
       '2023-01-05 10:00:00+00'),
(12,   'ACCOUNTS',     'UPDATE',
       '{"balance":50000.00}',
       '{"balance":92500.00}',
       '2023-06-01 12:00:00+00'),
(19,   'CARDS',        'UPDATE',
       '{"status":"APPROVED"}',
       '{"status":"DECLINED"}',
       '2024-07-01 00:00:00+00');

-- Function 1
CREATE OR REPLACE FUNCTION calculate_customer_daily_amount(in_customer_id bigint, in_target_date date)
returns NUMERIC(18, 2)
language plpgsql
as $$
declare
    out_daily_amount numeric(18, 2);
begin
    select
        sum(amount) as daily_amount
     into out_daily_amount
    from accounts a
    join transactions t on t.account_id = a.account_id
    where a.customer_id = in_customer_id and
          t.transaction_at::date = in_target_date;
    return out_daily_amount;
end;
$$;

select * from transactions;
select * from customers;

select calculate_customer_daily_amount(1, '2024-01-05'::date);

-- Function 2
CREATE OR REPLACE FUNCTION is_high_risk_country(in_country_code transactions.merchant_country%type)
returns boolean
language plpgsql
as $$
declare
    out_is_high_risk_country boolean;
begin
    select
    case
        when avg(risk_score) >= 70 then TRUE
        else FALSE
    end
    into out_is_high_risk_country
    from transactions
    where merchant_country = in_country_code;
    return out_is_high_risk_country;
end;
$$;

select is_high_risk_country('FR');

-- Function 3
CREATE OR REPLACE FUNCTION get_last_name(in_transaction_id transactions.transaction_id%type)
returns VARCHAR(100)
language plpgsql
as $$
declare
    out_last_name VARCHAR(100);
begin
    select last_name c
    into out_last_name
    from customers c
    join accounts a on c.customer_id = a.customer_id
    join transactions t on a.account_id = t.account_id
    where transaction_id = in_transaction_id;
    return out_last_name;
end;
$$;

select get_last_name('20');

-- Function 4
CREATE OR REPLACE FUNCTION get_age(in_customer_id customers.customer_id%type)
returns int
language plpgsql
as $$
declare
    out_age int;
begin
    select now() - birth_date
    into out_age
    from customers
    where customer_id = in_customer_id;
    return out_age;
end;
$$;

select get_age('1');

-- Function 5
drop function mask_card_number;
CREATE OR REPLACE FUNCTION mask_card_number(card_number varchar(18))
returns varchar(18)
language plpgsql
as $$
begin
    return REGEXP_REPLACE(card_number, '^(\d{4})(.+)(\d{4})$', '\1XXXXXXXX\3');
end;
$$;

select mask_card_number('2222444477778888');


-- Procedure 1
create or replace procedure completed_transaction(in_transaction_id transactions.transaction_id%type)
language plpgsql
as $$
begin
    update transactions
    set status = 'COMPLETED'
    where transaction_id = in_transaction_id;
end;
$$;

-- Procedure 2
create or replace procedure create_fraud_transaction(in_transaction_id transactions.transaction_id%type, in_reason fraud_alerts.reason%type, in_risk_score fraud_alerts.risk_score%type)
language plpgsql
as $$
begin
    insert into fraud_alerts(transaction_id, reason, risk_score)
    values (in_transaction_id, in_reason, in_risk_score);
end;
$$;

-- Procedure 3
create or replace procedure freeze_account(in_account_id ACCOUNTS.account_id%type)
language plpgsql
as $$
begin
    update accounts
    set status = 'FLAGGED'
    where account_id = in_account_id;
end;
$$;

-- Procedure 4
create or replace procedure refresh_fraud_dashboard()
language plpgsql
as $$
begin
    refresh materialized view vw_customer_risk_profile;
end;
$$;

-- Procedure 5
create or replace procedure reverse_transaction(in_transaction_id transactions.transaction_id%type)
language plpgsql
as $$
begin
    update transactions
    set status = 'PENDING'
    where in_transaction_id = transaction_id;
end;
$$;

-- Triger
create or replace function insert_fraud()
returns trigger as $$
begin
    if new.risk_score >= 75 then
    insert into fraud_alerts(transaction_id, rule_id, reason, risk_score)
    values (new.transaction_id, 7, 'High risk score', new.risk_score);
    end if;
    return new;
end;
$$ language plpgsql;

create trigger insert_fraud_alerts
after insert on transactions
for each row
execute function insert_fraud();

-- View 1
create view vw_customer_accounts as
    select *
    from accounts;

select * from vw_customer_accounts;

-- View 2
drop view vw_recent_transaction;


create view vw_recent_transaction as
    select *
    from transactions
    where transaction_at >= (select max(transaction_at) from transactions)- interval '1 week';

select * from vw_recent_transaction;

-- View 3
create view vw_flagged_transaction as
    select *
    from transactions
    where status = 'FLAGGED';

select * from vw_flagged_transaction;

-- View 4
create view vw_customer_risk_profile as
    select
        last_name,
        first_name,
        avg(t.risk_score) as avg_risk_score
    from customers c
    left join accounts a  on a.account_id = c.customer_id
    left join transactions t on t.transaction_id = a.account_id
    group by last_name, first_name
    order by avg(t.risk_score) desc;

select * from vw_customer_risk_profile;

-- Materialized View
drop materialized view mv_daily_fraud_summary;

create materialized view mv_daily_fraud_summary as
    with transactions_by_date as(
       select

        date(transaction_at) as transaction_date,
        count(transaction_id) as number_transaction,
        sum(amount) as total_amount,
        sum(case when status='FLAGGED' then  1 else 0 end) as count_flagged_transaction,
        sum(case when status='FLAGGED' then amount else 0 end) as flagged_total_amount,
        avg(risk_score) as avg_risk_score
    from transactions t
    group by date(transaction_at)),
    fraud_alerts_cte as(
        select
           count(*) as cnt_fraud,
            date(t.transaction_at) as transaction_date
        from fraud_alerts f
        join transactions t on t.transaction_id = f.transaction_id
        group by date(t.transaction_at)
        )
    select
            tt.*,
           COALESCE(ff.cnt_fraud, 0) as cnt_fraud
    from transactions_by_date tt
    left join fraud_alerts_cte ff on tt.transaction_date = ff.transaction_date;

select * from mv_daily_fraud_summary order by transaction_date desc;

create extension if not exists pg_cron;

refresh materialized view mv_daily_fraud_summary;

SELECT cron.schedule('fast-poll', '0 * * * *', 'refresh materialized view mv_daily_fraud_summary;');


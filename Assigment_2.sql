select * from customers;
select * from  products;
select * from ORDERS;
select count(*) from order_items;
select count(*) from customer_events_wide;

select * from pg_stat_statements;

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname NOT IN ('pg_catalog', 'information_schema');


SELECT
pid,
usename,
state,
xact_start,
now() - xact_start AS transaction_duration,
query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY xact_start;

SELECT
pid,
usename,
state,
xact_start,
now() - xact_start AS transaction_duration,
query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY xact_start;


SELECT
blocked.pid AS blocked_pid,
blocked.usename AS blocked_user,
blocked.query AS blocked_query,
blocking.pid AS blocking_pid,
blocking.usename AS blocking_user,
blocking.query AS blocking_query,
blocked.wait_event_type,
blocked.wait_event
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
ORDER BY blocked.pid;



SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC;

-- rename table to old
ALTER TABLE customer_events_wide RENAME TO customer_events_wide_old;

CREATE TABLE customer_events_wide (
                event_id BIGINT,
                customer_id INT,
                event_type TEXT,
                event_time TIMESTAMP,
                source TEXT,
                campaign TEXT,
                device TEXT,
                browser TEXT,
                os TEXT,
                ip_address TEXT,
                page_url TEXT,
                referrer TEXT,
                utm_source TEXT,
                utm_medium TEXT,
                utm_campaign TEXT,
                attr_01 TEXT,
                attr_02 TEXT,
                attr_03 TEXT,
                attr_04 TEXT,
                attr_05 TEXT,
                attr_06 TEXT,
                attr_07 TEXT,
                attr_08 TEXT,
                attr_09 TEXT,
                attr_10 TEXT,
                PRIMARY KEY (event_id, event_time)
            )  PARTITION BY RANGE (event_time);
-- Normalizetion

select event_type from customer_events_wide group by event_type;
select * from customer_events_wide_old;
select * from customer_events_wide;



create table event_types (
    event_type_id SERIAL PRIMARY KEY,
    event_type varchar(20) check(event_type in ('click', 'login', 'logout', 'page_view', 'purchase'))
);

with inseeted_event_types as(
    select distinct event_type
    from customer_events_wide_old
)
insert into event_types(event_type)
select * from inseeted_event_types;

create table device_profiles (
    device_profile_id SERIAL PRIMARY KEY,
    device varchar(20) check (device in ('desktop', 'mobile', 'tablet')),
    source varchar(20) check (source in ('direct', 'email', 'facebook', 'google', 'tiktok')),
    browser varchar(20) check (browser in ('chrome', 'edge', 'firefox', 'safari')),
    os varchar(20) check (os in ('android', 'ios', 'linux', 'macos', 'windows')),
    unique (device, source, browser, os)
);

WITH inserted_profiles AS (
    SELECT DISTINCT device, source, browser, os
    FROM customer_events_wide_old
)
INSERT INTO device_profiles (device, source, browser, os)
select *
from inserted_profiles;

drop table customer_events;
CREATE TABLE customer_events (
    event_id SERIAL,
    customer_id INT,
    customer_status TEXT,
    event_time TIMESTAMP NOT NULL,
    event_type_id INT REFERENCES event_types(event_type_id),
    device_profile_id INT REFERENCES device_profiles(device_profile_id),
    ip_address INET,
    page_url TEXT,
    referrer TEXT,
    event_payload JSONB,
    PRIMARY KEY (event_id, event_time),
    FOREIGN KEY (customer_id, customer_status) REFERENCES customers(customer_id, status)
) PARTITION BY RANGE (event_time);

CREATE TABLE customer_events_2026_03 PARTITION OF customer_events
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE customer_events_2026_04 PARTITION OF customer_events
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE customer_events_2026_05 PARTITION OF customer_events
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE customer_events_2026_06 PARTITION OF customer_events
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE customer_events_2026_07 PARTITION OF customer_events
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE customer_events_default PARTITION OF customer_events DEFAULT;

drop index idx_customer_events;
create index idx_customer_events
on customer_events
using brin(event_time);

INSERT INTO customer_events (customer_id, event_time, event_type_id, device_profile_id, ip_address, page_url, referrer, event_payload)
SELECT
    ce.customer_id, ce.event_time, et.event_type_id, dp.device_profile_id,
    CAST(ce.ip_address AS inet),
    ce.page_url,
    ce.referrer,
    jsonb_strip_nulls(
        jsonb_build_object(
            'utm_source', ce.utm_source,
            'utc_medium', ce.utm_medium,
            'utc_campaign', ce.utm_campaign,
            'attr_01', attr_01,
            'attr_02', attr_02,
            'attr_03', attr_03,
            'attr_04', attr_04,
            'attr_05', attr_05,
            'attr_06', attr_06,
            'attr_07', attr_07,
            'attr_08', attr_08,
            'attr_09', attr_09,
            'attr_10', attr_10
        )
    ) AS event_payload

from customer_events_wide_old ce, device_profiles dp, event_types et
where (ce.os = dp.os) and (ce.device = dp.device) and
      (ce.browser = dp.browser) and (ce.source = dp.source) and
      (ce.event_type = et.event_type);


select count(*) from customer_events;

-- events_aggregation
-- total exec time Execution Time: 62.009 ms
-- After brin index ~42m
-- With partitioning ~30ms and with index ~24-25
/*
explain analyse
SELECT
    customer_id,
    event_type,
    COUNT(*) AS events_count,
    MAX(event_time) AS last_event_time
FROM customer_events_wide_old
WHERE event_time >= NOW() - '2 days'::interval
GROUP BY customer_id, event_type
ORDER BY events_count DESC
LIMIT 100;
*/

-- With standart form and  partitioning: 14ms
-- Add index brin: 10ms
explain analyse
SELECT
    c.customer_id,
    e.event_type,
    COUNT(c.event_id) AS events_count,
    MAX(c.event_time) AS last_event_time
FROM customer_events c
join event_types e on c.event_type_id = e.event_type_id
WHERE c.event_time >= NOW() - '2 days'::interval
GROUP BY c.customer_id, e.event_type
ORDER BY events_count DESC
LIMIT 100;



INSERT INTO customer_events_wide
SELECT * FROM customer_events_wide_old;

-- items_products_join
-- Execution Time: 113.554 ms
-- After PARTITION and adding index
-- 70-75ms
SET LOCAL enable_partitionwise_aggregate = on;
explain analyse
SELECT
    p.category,
    COUNT(*) AS items_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

alter table products rename to products_old;

CREATE TABLE products (
    product_id BIGINT,
    product_name TEXT,
    category varchar(20),
    price NUMERIC(10, 2),
    supplier TEXT,
    created_at TIMESTAMP,
    primary key (product_id, category)
) PARTITION BY list (category);

CREATE TABLE books PARTITION OF products
    FOR VALUES IN ('books');

CREATE TABLE  home PARTITION OF products
    FOR VALUES IN ('home');

CREATE TABLE  food PARTITION OF products
    FOR VALUES IN ('food');

CREATE TABLE  electronics PARTITION OF products
    FOR VALUES IN ('electronics');

CREATE TABLE clothes PARTITION OF products
    FOR VALUES IN ('clothes');

CREATE INDEX idx_order_items_covering ON order_items (product_id, quantity, unit_price);

insert into products
select *
from products_old;

select category from products_old group by category;
create view items_revenue as
SELECT
    p.category,
    COUNT(*) AS items_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category;

-- Execution Time: 0.274 ms
explain analyse
select *
from items_revenue
order by revenue desc;


-- cartesian_pressure
-- Execution Time: 96 ms
-- After remaking index: Execution Time: 91.548 ms
-- After PARTITION and making brin index: ~60 ms
explain analyse
SELECT COUNT(*)
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN customer_events e ON e.customer_id = c.customer_id
WHERE c.status IN ('active', 'inactive')
  AND e.event_time >= NOW() - INTERVAL '90 days';

create index idx_customer_events
on customer_events
using brin(event_time);

select count(*) from orders;
-- make PARTITION
drop table customers;
alter table customers rename to customers_old;

CREATE TABLE customers (
    customer_id SERIAL,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    city TEXT,
    country TEXT,
    created_at TIMESTAMP,
    status TEXT,
    primary key (customer_id, status)
) PARTITION BY LIST (status);

select count(*) from customers_old;

CREATE TABLE inactive_customers PARTITION OF customers
    FOR VALUES IN ('inactive');

CREATE TABLE active_customers PARTITION OF customers
    FOR VALUES IN ('active');

CREATE TABLE blocked_customers PARTITION OF customers FOR VALUES IN ('blocked');

insert into customers
select *
from customers_old;

-- rewrite with cte
-- with
explain analyse
with customers_cte as(
    select *
    from customers
    where status IN ('active', 'inactive')),
customer_events as(
    select *
    from customer_events
    where event_time >= NOW() - INTERVAL '90 days'
    )
select count(*)
from customers_cte c
JOIN orders o ON o.customer_id = c.customer_id
JOIN customer_events e ON e.customer_id = c.customer_id;

drop index idx_orders_customer_include;
create index CONCURRENTLY idx_orders_customer_include
on customers(customer_id) include(status);

-- ГЛАВА 3. СОЗДАНИЕ СХЕМ И ТАБЛИЦ.

--(TODO: НОРМАЛИЗОВАТЬ ДОКУМЕНТАЦИЮ, ПРОВЕРИТЬ ИНДЕКСЫ И ЧЕКИ)

-- Создание схемы данных склада
DROP SCHEMA IF exists storage CASCADE;
CREATE SCHEMA storage;

CREATE TABLE storage.categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

/*CREATE TABLE storage.suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_info TEXT
);*/

CREATE TABLE storage.products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    category_id INT REFERENCES storage.categories(category_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    description TEXT,
    total_quantity INT NOT NULL DEFAULT 0 CHECK (total_quantity >= 0),
    reserved_quantity INT NOT NULL DEFAULT 0 CHECK (reserved_quantity <= total_quantity)
);

/*CREATE TABLE storage.product_suppliers (
    product_id INT REFERENCES storage.products(product_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    supplier_id INT REFERENCES storage.suppliers(supplier_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    PRIMARY KEY (product_id, supplier_id)
);*/

CREATE TABLE storage.product_batches (
    batch_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES storage.products(product_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
/*    supplier_id INT REFERENCES storage.suppliers(supplier_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,*/
    purchase_price DECIMAL(10, 2) NOT NULL CHECK (purchase_price > 0),
    selling_price DECIMAL(10, 2) NOT NULL CHECK (selling_price >= purchase_price),
    quantity INT NOT NULL CHECK (quantity > 0),
    arrival_date DATE NOT NULL CHECK (arrival_date <= CURRENT_DATE)
);


-- Создание схемы данных продаж
DROP SCHEMA IF EXISTS sales CASCADE;
CREATE SCHEMA sales;

CREATE TABLE sales.customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE sales.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES sales.customers(customer_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) NOT NULL CHECK (status IN ('оформлен', 'оплачен', 'доставлен', 'отменён')),
    shipping_address TEXT NOT NULL
);

CREATE TABLE sales.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES sales.orders(order_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0)
);


--Создание админ-схемы с логами и пользователями
DROP SCHEMA IF EXISTS admin CASCADE;
CREATE SCHEMA admin;

--Таблица с логом действий 
CREATE TABLE admin.action_logs (
    action_id SERIAL PRIMARY KEY,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    action_details JSONB,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INT DEFAULT 1  --Админ по умолчанию для тестов, может потом удалю
);

CREATE INDEX idx_action_logs_action_time ON admin.action_logs (action_time);
CREATE INDEX idx_action_logs_table_name ON admin.action_logs (table_name);
CREATE INDEX idx_action_logs_record_id ON admin.action_logs (record_id);
CREATE INDEX idx_action_logs_user_id ON admin.action_logs (user_id);

--Таблица с логом ошибок
CREATE TABLE admin.error_logs (
    error_id SERIAL PRIMARY KEY,
    error_message TEXT NOT NULL,
    error_details JSONB,
    error_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INT DEFAULT 1  -- Также админ по умолчанию, всё равно я админ (!УДАЛИТЬ КОММЕНТАРИИ!)
);

CREATE INDEX idx_error_logs_error_time ON admin.error_logs (error_time);
CREATE INDEX idx_error_logs_user_id ON admin.error_logs (user_id);


/*
TRUNCATE TABLE admin.action_logs, admin.error_logs RESTART IDENTITY;
TRUNCATE TABLE storage.product_batches, /*storage.product_suppliers, storage.suppliers,*/ storage.products, storage.categories RESTART IDENTITY;
TRUNCATE TABLE sales.customers, sales.order_items, sales.orders RESTART IDENTITY;
*/

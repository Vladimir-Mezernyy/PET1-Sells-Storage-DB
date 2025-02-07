-- ГЛАВА 5. СОЗДАНИЕ РАЗНОГО РОДА ФУНКЦИЙ И ТРИГГЕРОВ

-- ЧАСТЬ 1. ФУНКЦИИ ВЫБОРКИ

-- 1.1. ПРОСТЫЕ СЕЛЕКТЫ

-- 1.1.1. Функция для отображения всех поставщиков (ВЫРЕЗАНО)
/*CREATE OR REPLACE FUNCTION storage.get_all_suppliers()
RETURNS TABLE (
    supplier_id INT,
    name VARCHAR,
    contact_info TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.supplier_id, s.name, s.contact_info
    FROM storage.suppliers s
	ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.get_all_suppliers();*/

-- 1.1.2. Функция для отображения всех клиентов
CREATE OR REPLACE FUNCTION sales.get_all_customers()
RETURNS TABLE (
    customer_id INT,
    name VARCHAR,
    email VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.customer_id, c.name, c.email
    FROM sales.customers c
	ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_all_customers();

-- 1.1.3. Функция для отображения всех заказов
CREATE OR REPLACE FUNCTION sales.get_all_orders()
RETURNS TABLE (
    order_id INT,
    customer_id INT,
    order_date DATE,
    status VARCHAR,
    shipping_address TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.customer_id, o.order_date, o.status, o.shipping_address
    FROM sales.orders o
    ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.get_all_orders();

-- 1.1.4. Функция для отображения всех товаров в заказах
CREATE OR REPLACE FUNCTION sales.get_all_order_items()
RETURNS TABLE (
    order_item_id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT oi.order_item_id, oi.order_id, oi.product_id, oi.quantity, oi.price
    FROM sales.order_items oi
    ORDER BY 2, 1, 3;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.get_all_order_items();

-- 1.1.5. Функция для отображения всех категорий товаров
CREATE OR REPLACE FUNCTION storage.get_all_categories()
RETURNS TABLE (
    category_id INT,
    name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.category_id, c.name
    FROM storage.categories c
	ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.get_all_categories();

-- 1.1.6. Функция для отображения всех товаров и их количества
CREATE OR REPLACE FUNCTION storage.get_all_products()
RETURNS TABLE (
    product_id INT,
    name VARCHAR,
    category_id INT,
    description TEXT,
    total_quantity INT,
    reserved_quantity INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, p.category_id, p.description, p.total_quantity, p.reserved_quantity
    FROM storage.products p
	ORDER BY 3, 1;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.get_all_products();

-- 1.1.7. Функция для отображения всех партий товаров
CREATE OR REPLACE FUNCTION storage.get_all_batches()
RETURNS TABLE (
    batch_id INT,
    product_id INT,
/*    supplier_id INT,*/
    purchase_price DECIMAL(10, 2),
    selling_price DECIMAL(10, 2),
    quantity INT,
    arrival_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT pb.batch_id, pb.product_id, /*pb_supplier_id,*/ pb.purchase_price, pb.selling_price, pb.quantity, pb.arrival_date
    FROM storage.product_batches pb
	ORDER BY 1, 2, 6;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.get_all_batches();

-----------------------------------------

-- 1.2. СРЕДНИЕ ПО СЛОЖНОСТИ СЕЛЕКТЫ

-- 1.2.1. Функция топ 5 товаров по популярности по количеству продаж
CREATE OR REPLACE FUNCTION sales.get_top_5_products_by_sales()
RETURNS TABLE (
    product_id INT,
    product_name VARCHAR,
    total_sales INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.product_id,
        p.name,
        SUM(oi.quantity)::INT
    FROM
        sales.order_items oi
        JOIN storage.products p ON oi.product_id = p.product_id
    GROUP BY
        p.product_id, p.name
    ORDER BY
        SUM(oi.quantity) DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_top_5_products_by_sales();

-- 1.2.2. Средняя выручка по категориям за последний месяц
CREATE OR REPLACE FUNCTION sales.get_avg_revenue_by_category_last_month()
RETURNS TABLE (
    category_name VARCHAR,
    avg_revenue DECIMAL(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.name,
        AVG(oi.quantity * oi.price)
    FROM
        sales.order_items oi
        JOIN storage.products p ON oi.product_id = p.product_id
        JOIN storage.categories c ON p.category_id = c.category_id
        JOIN sales.orders o ON oi.order_id = o.order_id
    WHERE
        o.order_date >= NOW() - INTERVAL '1 month'
    GROUP BY
        c.name;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_avg_revenue_by_category_last_month();

-- 1.2.3. Товары с низким остатком на складе (параметр - минимальный остаток, ниже которого товар отобразитчя в запросе)
CREATE OR REPLACE FUNCTION storage.get_low_stock_products(threshold INT)
RETURNS TABLE (
    product_id INT,
    product_name VARCHAR,
    total_quantity INT,
    reserved_quantity INT,
    available_quantity INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.product_id,
        p.name,
        p.total_quantity,
        p.reserved_quantity,
        p.total_quantity - p.reserved_quantity
    FROM
        storage.products p
    WHERE
        p.total_quantity - p.reserved_quantity < threshold
	ORDER BY
		1;
END;
$$ LANGUAGE plpgsql;

-- Пример
--SELECT * FROM storage.get_low_stock_products(20);

-- 1.2.4. Подсчёт количества заказов товаров по месяцам
CREATE OR REPLACE FUNCTION sales.get_orders_by_month()
RETURNS TABLE (
    month TEXT,
    order_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(o.order_date, 'YYYY-MM'),
        COUNT(*)::INT
    FROM
        sales.orders o
    GROUP BY
        TO_CHAR(o.order_date, 'YYYY-MM')
    ORDER BY
        TO_CHAR(o.order_date, 'YYYY-MM');
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_orders_by_month();

-- 1.2.5. Показ витрины склада
CREATE OR REPLACE FUNCTION storage.get_storage_data()
RETURNS TABLE (
    "Идентификатор товара" INT,
    "Название товара" VARCHAR,
    "Категория" VARCHAR,
--    "Поставщик" VARCHAR,
    "Общее количество" INT,
    "Зарезервировано" INT,
    "Доступно" INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM storage.storage_data_view;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.get_storage_data();

-- 1.2.6. Показ витрины продаж
CREATE OR REPLACE FUNCTION sales.get_finance_data()
RETURNS TABLE (
    "Идентификатор заказа" INT,
    "Дата заказа" DATE,
    "Клиент" VARCHAR,
    "Выручка" DECIMAL(10, 2),
    "Себестоимость" DECIMAL(10, 2),
    "Прибыль" DECIMAL(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM sales.sales_finance_data_view;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_finance_data();

-- 1.2.7. Показ витрины суммарной прибыли по партиям продуктов за 1 единицу товаров
CREATE OR REPLACE FUNCTION sales.get_product_revenue_summary()
RETURNS TABLE (
    "Идентификатор товара" INT,
    "Название товара" VARCHAR,
    "Категория" VARCHAR,
    "Суммарная выручка" DECIMAL(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM sales.product_revenue_summary;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_product_revenue_summary()

-----------------------------------------

-- 1.3. СЛОЖНЫЕ СЕЛЕКТЫ

-- 1.3.1. Отображение скользящей средней выручки за последние три месяца
CREATE OR REPLACE FUNCTION sales.get_3_month_moving_avg_revenue()
RETURNS TABLE (
    "Месяц" TEXT,
    "Выручка" DECIMAL(10, 2),
    "Скользящее среднее" DECIMAL(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        month,
        revenue,
        AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
    FROM (
        SELECT
            TO_CHAR(o.order_date, 'YYYY-MM') AS month,
            SUM(oi.quantity * oi.price) AS revenue
        FROM
            sales.order_items oi
            JOIN sales.orders o ON oi.order_id = o.order_id
        GROUP BY
            TO_CHAR(o.order_date, 'YYYY-MM')
    ) AS monthly_revenue
    ORDER BY
        month;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_3_month_moving_avg_revenue();

-- 1.3.2. Самые прибыльные товары в каждой из категорий
CREATE OR REPLACE FUNCTION sales.get_top_profitable_products_by_category()
RETURNS TABLE (
    "Название категории" VARCHAR,
    "Название продукта" VARCHAR,
    "Суммарная выручка" DECIMAL(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        category_name,
        product_name,
        total_profit
    FROM (
        SELECT
            c.name AS category_name,
            p.name AS product_name,
            SUM(oi.price - pb.purchase_price) AS total_profit,
            RANK() OVER (PARTITION BY c.name ORDER BY SUM(oi.quantity * (oi.price - pb.purchase_price)) DESC) AS rank
        FROM
            sales.order_items oi
            JOIN storage.products p ON oi.product_id = p.product_id
            JOIN storage.categories c ON p.category_id = c.category_id
            JOIN storage.product_batches pb ON oi.product_id = pb.product_id
        GROUP BY
            c.name, p.name
    ) AS ranked_products
    WHERE
        rank = 1;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_top_profitable_products_by_category();

-- 1.3.3. Клиенты, совершавшие заказ в каждый из месяцев за последние три месяца
CREATE OR REPLACE FUNCTION sales.get_loyal_customers()
RETURNS TABLE (
    "ID клиента" INT,
    "Имя клиента" VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        customer_id,
        name AS customer_name
    FROM (
        SELECT
            c.customer_id,
            c.name,
            TO_CHAR(o.order_date, 'YYYY-MM') AS month
        FROM
            sales.customers c
            JOIN sales.orders o ON c.customer_id = o.customer_id
        WHERE
            o.order_date >= NOW() - INTERVAL '3 month'
        GROUP BY
            c.customer_id, c.name, TO_CHAR(o.order_date, 'YYYY-MM')
    ) AS monthly_orders
    GROUP BY
        customer_id, name
    HAVING
        COUNT(DISTINCT month) = 3;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.get_loyal_customers();

-----------------------------------------
-----------------------------------------

-- 2. ФУНКЦИИ ДЛЯ ВНЕСЕНИЯ ДАННЫХ/ИХ ИЗЕНЕНИЯ/УДАЛЕНИЯ В СХЕМУ storage

-- 2.1. Работа с supplier (ВЫРЕЗАНО!!!)
/*
-- 2.1.1 INSERT
CREATE OR REPLACE FUNCTION storage.add_supplier(
    supplier_name VARCHAR,
    contact_info TEXT
) RETURNS VOID AS $$
BEGIN
    INSERT INTO storage.suppliers (name, contact_info)
    VALUES (supplier_name, contact_info);
END;
$$ LANGUAGE plpgsql;

-- Пример
--SELECT * FROM add_supplier('Новый поставщик', 'info@new-supplier.com');

-- 2.1.2 UPDATE
CREATE OR REPLACE FUNCTION storage.update_supplier(
    supplier_id INT,
    new_name VARCHAR,
    new_contact_info TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE storage.suppliers
    SET name = new_name,
        contact_info = new_contact_info
    WHERE supplier_id = update_supplier.supplier_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
--SELECT * FROM update_supplier(1, 'Обновлённый поставщик', 'new-info@supplier.com');

-- 2.1.3 DELETE
CREATE OR REPLACE FUNCTION storage.delete_supplier(
    supplier_id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM storage.suppliers
    WHERE supplier_id = delete_supplier.supplier_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
--SELECT * FROM delete_supplier(1);
*/

-----------------------------------------

-- 2.2. Работа с categories

-- 2.2.1 INSERT
CREATE OR REPLACE FUNCTION storage.add_category(
    category_name VARCHAR
) RETURNS INT AS $$
DECLARE
    new_category_id INT;
BEGIN
    INSERT INTO storage.categories (name)
    VALUES (category_name)
    RETURNING category_id INTO new_category_id;

    RETURN new_category_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.add_category('Новая категория');

-- 2.2.2 UPDATE
CREATE OR REPLACE FUNCTION storage.update_category(
    id INT,
    new_name VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE storage.categories
    SET name = new_name
    WHERE category_id = update_category.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
--SELECT * FROM storage.update_category(1, 'Обновлённая категория');

-- 2.2.3 DELETE
CREATE OR REPLACE FUNCTION storage.delete_category(
    id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM storage.categories
    WHERE category_id = delete_category.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.delete_category(1);

-----------------------------------------

-- 2.3. Работа с products

-- 2.3.1 INSERT
CREATE OR REPLACE FUNCTION storage.add_product(
    product_name VARCHAR,
    id INT,
    descr TEXT,
    t_quantity INT,
    r_quantity INT
) RETURNS INT AS $$
DECLARE
    new_product_id INT;
BEGIN
    INSERT INTO storage.products (name, category_id, description, total_quantity, reserved_quantity)
    VALUES (product_name, id, descr, t_quantity, r_quantity)
    RETURNING product_id INTO new_product_id;

    RETURN new_product_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.add_product('Новый товар', 1, 'Описание нового товара', 100, 10);

-- 2.3.2 UPDATE
CREATE OR REPLACE FUNCTION storage.update_product(
    id INT,
    new_name VARCHAR,
    new_category_id INT,
    new_description TEXT,
    new_total_quantity INT,
    new_reserved_quantity INT
) RETURNS VOID AS $$
BEGIN
    UPDATE storage.products
    SET name = new_name,
        category_id = new_category_id,
        description = new_description,
        total_quantity = new_total_quantity,
        reserved_quantity = new_reserved_quantity
    WHERE product_id = update_product.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.update_product(1, 'Обновлённый товар', 2, 'Новое описание', 150, 20);

-- 2.3.3 DELETE
CREATE OR REPLACE FUNCTION storage.delete_product(
    id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM storage.products
    WHERE product_id = delete_product.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.delete_product(1);

-----------------------------------------

/* 2.4. Работа с product_suppliers (ВЫРЕЗАНО!!!)

-- 2.4.1 INSERT
CREATE OR REPLACE FUNCTION storage.add_product_supplier(
    product_id INT,
    supplier_id INT
) RETURNS VOID AS $$
BEGIN
    INSERT INTO storage.product_suppliers (product_id, supplier_id)
    VALUES (product_id, supplier_id);
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.add_product_supplier(1, 1);

-- 2.4.2 UPDATE
CREATE OR REPLACE FUNCTION storage.update_product_supplier(
    old_product_id INT,
    old_supplier_id INT,
    new_product_id INT,
    new_supplier_id INT
) RETURNS VOID AS $$
BEGIN
    UPDATE storage.product_suppliers
    SET product_id = new_product_id,
        supplier_id = new_supplier_id
    WHERE product_id = old_product_id AND supplier_id = old_supplier_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.update_product_supplier(1, 1, 2, 2);

-- 2.4.3 DELETE
CREATE OR REPLACE FUNCTION storage.delete_product_supplier(
    product_id INT,
    supplier_id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM storage.product_suppliers
    WHERE product_id = delete_product_supplier.product_id
      AND supplier_id = delete_product_supplier.supplier_id;
END;
$$ LANGUAGE plpgsql;

-- Пример*/
-- SELECT * FROM storage.delete_product_supplier(1, 1);

-----------------------------------------

-- 2.5. Работа с product_batches

-- 2.5.1 INSERT
CREATE OR REPLACE FUNCTION storage.add_product_batch(
    id INT,
--    supplier_id INT,
    p_price DECIMAL(10, 2),
    s_price DECIMAL(10, 2),
    quant INT,
    a_date DATE
) RETURNS INT AS $$
DECLARE
    new_batch_id INT;
BEGIN
    INSERT INTO storage.product_batches (product_id, /*supplier_id,*/ purchase_price, selling_price, quantity, arrival_date)
    VALUES (id, /*supplier_id,*/ p_price, s_price, quant, a_date)
    RETURNING batch_id INTO new_batch_id;

    RETURN new_batch_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.add_product_batch(1, 10000.00, 15000.00, 50, '2023-10-01');

-- 2.5.2 UPDATE
CREATE OR REPLACE FUNCTION storage.update_product_batch(
    id INT,
    new_product_id INT,
--    new_supplier_id INT,
    new_purchase_price DECIMAL(10, 2),
    new_selling_price DECIMAL(10, 2),
    new_quantity INT,
    new_arrival_date DATE
) RETURNS VOID AS $$
BEGIN
    UPDATE storage.product_batches
    SET product_id = new_product_id,
--        supplier_id = new_supplier_id,
        purchase_price = new_purchase_price,
        selling_price = new_selling_price,
        quantity = new_quantity,
        arrival_date = new_arrival_date
    WHERE batch_id = update_product_batch.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.update_product_batch(1, 2, 12000.00, 18000.00, 60, '2023-10-05');

-- 2.5.3 DELETE
CREATE OR REPLACE FUNCTION storage.delete_product_batch(
    id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM storage.product_batches
    WHERE batch_id = delete_product_batch.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM storage.delete_product_batch(1);

-----------------------------------------
-----------------------------------------

-- 3. ФУНКЦИИ ДЛЯ ВНЕСЕНИЯ ДАННЫХ/ИХ ИЗМЕНЕНИЯ/УДАЛЕНИЯ В СХЕМУ sales

-- 3.1. Работа с customers

-- 3.1.1 INSERT
CREATE OR REPLACE FUNCTION sales.add_customer(
    customer_name VARCHAR,
    new_email VARCHAR
) RETURNS INT AS $$
DECLARE
    new_customer_id INT;
BEGIN
    INSERT INTO sales.customers (name, email)
    VALUES (customer_name, new_email)
    RETURNING customer_id INTO new_customer_id;

    RETURN new_customer_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.add_customer('Новый клиент', 'new-customer@example.com');

-- 3.1.2 UPDATE
CREATE OR REPLACE FUNCTION sales.update_customer(
    id INT,
    new_name VARCHAR,
    new_email VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE sales.customers
    SET name = new_name,
        email = new_email
    WHERE customer_id = update_customer.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.update_customer(1, 'Обновлённый клиент', 'updated-customer@example.com');

-- 3.1.3 DELETE
CREATE OR REPLACE FUNCTION sales.delete_customer(
    id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM sales.customers
    WHERE customer_id = delete_customer.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.delete_customer(1);

-----------------------------------------

-- 3.2. Работа с orders

-- 3.2.1 INSERT
CREATE OR REPLACE FUNCTION sales.add_order(
    id INT,
    new_date DATE,
    new_status VARCHAR,
    new_shipping_address TEXT
) RETURNS INT AS $$
DECLARE
    new_order_id INT;
BEGIN
    INSERT INTO sales.orders (customer_id, order_date, status, shipping_address)
    VALUES (id, new_date, new_status, new_shipping_address)
    RETURNING order_id INTO new_order_id;

    RETURN new_order_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.add_order(1, CURRENT_DATE, "оформлен", 'ул. Ленина, д. 10');

-- 3.2.2 UPDATE
CREATE OR REPLACE FUNCTION sales.update_order(
    id INT,
    new_customer_id INT,
    new_order_date DATE,
    new_status VARCHAR,
    new_shipping_address TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE sales.orders
    SET customer_id = new_customer_id,
		order_date = new_order_date,
		status = new_status,
        shipping_address = new_shipping_address
    WHERE order_id = update_order.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.update_order(1, CURRENT_DATE, 'отменён', 'ул. Ленина, д. 15');

-- 3.2.3 DELETE
CREATE OR REPLACE FUNCTION sales.delete_order(
    id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM sales.orders
    WHERE order_id = delete_order.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.delete_order(1);

-----------------------------------------

-- 3.3. Работа с order_items

-- 3.3.1 INSERT
CREATE OR REPLACE FUNCTION sales.add_order_item(
    new_order_id INT,
    new_product_id INT,
    new_quantity INT,
    new_price DECIMAL(10, 2)
) RETURNS INT AS $$
DECLARE
    new_order_item_id INT;
BEGIN
    INSERT INTO sales.order_items (order_id, product_id, quantity, price)
    VALUES (new_order_id, new_product_id, new_quantity, new_price)    
	RETURNING order_item_id INTO new_order_item_id;

    RETURN new_order_item_id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.add_order_item(1, 1, 2, 25000.00);

-- 3.3.2 UPDATE
CREATE OR REPLACE FUNCTION sales.update_order_item(
    id INT,
    new_order_id INT,
    new_product_id INT,
    new_quantity INT,
    new_price DECIMAL(10, 2)
) RETURNS VOID AS $$
BEGIN
    UPDATE sales.order_items
    SET order_id = new_order_id,
        product_id = new_product_id,
        quantity = new_quantity,
        price = new_price
    WHERE order_item_id = update_order_item.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.update_order_item(1, 2, 2, 3, 30000.00);

-- 3.3.3 DELETE
CREATE OR REPLACE FUNCTION sales.delete_order_item(
    id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM sales.order_items
    WHERE order_item_id = delete_order_item.id;
END;
$$ LANGUAGE plpgsql;

-- Пример
-- SELECT * FROM sales.delete_order_item(1);

-----------------------------------------
-----------------------------------------

-- 4. ТРИГГЕРЫ

-- 4.1. ЛОГГИРОВАНИЕ

-- 4.1.1 Триггер для сохранения логов
CREATE OR REPLACE FUNCTION admin.log_all_changes_and_errors()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
    record_id INT;
    primary_key_column TEXT;
BEGIN
    -- Определяем имя первичного ключа таблицы
    SELECT a.attname INTO primary_key_column
    FROM pg_index i
    JOIN pg_attribute a ON a.attnum = ANY(i.indkey) AND a.attrelid = i.indrelid
    WHERE i.indrelid = TG_RELID AND i.indisprimary;

    -- Определяем данные для логирования
    IF TG_OP = 'INSERT' THEN
        old_data := NULL;
        new_data := row_to_json(NEW);
        record_id := (row_to_json(NEW) ->> primary_key_column)::INT;  -- Получаем значение первичного ключа
    ELSIF TG_OP = 'UPDATE' THEN
        old_data := row_to_json(OLD);
        new_data := row_to_json(NEW);
        record_id := (row_to_json(NEW) ->> primary_key_column)::INT;  -- Получаем значение первичного ключа
    ELSIF TG_OP = 'DELETE' THEN
        old_data := row_to_json(OLD);
        new_data := NULL;
        record_id := (row_to_json(OLD) ->> primary_key_column)::INT;  -- Получаем значение первичного ключа
    END IF;

    -- Логируем действие
    INSERT INTO admin.action_logs (action_type, table_name, record_id, action_details)
    VALUES (TG_OP, TG_TABLE_NAME, record_id, jsonb_build_object('old', old_data, 'new', new_data));

    RETURN NEW;

EXCEPTION
    WHEN others THEN
        -- Логируем ошибку
        INSERT INTO admin.error_logs (error_message, error_details)
        VALUES (SQLERRM, jsonb_build_object('table', TG_TABLE_NAME, 'operation', TG_OP, 'record_id', record_id));

        -- Продолжаем выполнение (если это допустимо)
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4.1.2 Подвязывание триггера под базовые виды функций
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'storage'
    LOOP
        EXECUTE format('
            CREATE TRIGGER trg_%s_changes
            AFTER INSERT OR UPDATE OR DELETE ON storage.%I
            FOR EACH ROW
            EXECUTE FUNCTION admin.log_all_changes_and_errors();
        ', table_name, table_name);
    END LOOP;

    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'sales'
    LOOP
        EXECUTE format('
            CREATE TRIGGER trg_%s_changes
            AFTER INSERT OR UPDATE OR DELETE ON sales.%I
            FOR EACH ROW
            EXECUTE FUNCTION admin.log_all_changes_and_errors();
        ', table_name, table_name);
    END LOOP;
END $$;

-----------------------------------------

-- 4.2. ОБНОВЛЕНИЕ ТАБЛИЦ ПРИ ИЗМЕНЕНИЯХ

-- 4.2.1. Обновление общего количества товаров при добавлении партии
CREATE OR REPLACE FUNCTION storage.update_total_quantity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE storage.products
    SET total_quantity = total_quantity + NEW.quantity
    WHERE product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Подвязывание
CREATE TRIGGER trg_update_total_quantity
AFTER INSERT ON storage.product_batches
FOR EACH ROW
EXECUTE FUNCTION storage.update_total_quantity();

-- 4.2.2. Проверка наличия достаточного количества товара при резервировании
CREATE OR REPLACE FUNCTION sales.check_product_availability()
RETURNS TRIGGER AS $$
DECLARE
    available_quantity INT;
BEGIN
    SELECT total_quantity - reserved_quantity
    INTO available_quantity
    FROM storage.products
    WHERE product_id = NEW.product_id;

    IF available_quantity < NEW.quantity THEN
        RAISE EXCEPTION 'Недостаточно товара на складе. Доступно: %, запрошено: %', available_quantity, NEW.quantity;
    END IF;

    UPDATE storage.products
    SET reserved_quantity = reserved_quantity + NEW.quantity
    WHERE product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Подвязывание
CREATE TRIGGER trg_check_product_availability
BEFORE INSERT ON sales.order_items
FOR EACH ROW
EXECUTE FUNCTION sales.check_product_availability();



-- ГЛАВА 4. СОЗДАНИЕ ВИТРИН ДАННЫХ

-- ЧАСТЬ 1. Витрина для отображения остатков товаров на складе
CREATE OR REPLACE VIEW storage.storage_data_view AS
SELECT
    p.product_id AS "Идентификатор товара",
    p.name AS "Название товара",
    c.name AS "Категория",
--    s.name AS "Поставщик",
    p.total_quantity AS "Общее количество",
    p.reserved_quantity AS "Зарезервировано",
    p.total_quantity - p.reserved_quantity AS "Доступно"
FROM
    storage.categories c
    JOIN storage.products p  ON c.category_id = p.category_id
/*    LEFT JOIN storage.product_suppliers ps ON p.product_id = ps.product_id
	LEFT JOIN storage.suppliers s on s.supplier_id = s.supplier_id*/
GROUP BY
    p.product_id, p.name, c.name --, s.name
ORDER BY
	1, 3;

-- Пример:
--SELECT * FROM storage.storage_data_view;

-- ЧАСТЬ 2. Витрина для отображения прибыли
CREATE OR REPLACE VIEW sales.sales_finance_data_view AS
SELECT
    o.order_id AS "Идентификатор заказа",
    o.order_date AS "Дата заказа",
    c.name AS "Клиент",
    SUM(oi.quantity * oi.price) AS "Выручка",
    SUM(oi.quantity * pb.purchase_price) AS "Себестоимость",
    SUM(oi.quantity * oi.price) - SUM(oi.quantity * pb.purchase_price) AS "Прибыль"
FROM
    sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN storage.product_batches pb ON oi.product_id = pb.product_id
    JOIN sales.customers c ON o.customer_id = c.customer_id
GROUP BY
    o.order_id, o.order_date, c.name
ORDER BY 
	2, 3, 1;

-- Пример:
--SELECT * FROM storage.storage_data_view;

-- ЧАСТЬ 3. Витрина для отображения суммарной по партиям выручки по каждому товару за 1 единицу товара
CREATE OR REPLACE VIEW sales.product_revenue_summary AS
SELECT
    p.product_id AS "Идентификатор товара",
    p.name AS "Название товара",
    c.name AS "Категория",
    SUM(oi.price - pb.purchase_price) AS "Суммарная выручка"
FROM
    sales.order_items oi
    JOIN storage.products p ON oi.product_id = p.product_id
    JOIN storage.categories c ON p.category_id = c.category_id
    JOIN storage.product_batches pb ON oi.product_id = pb.product_id
GROUP BY
    p.product_id, p.name, c.name
ORDER BY 
	1, 3;
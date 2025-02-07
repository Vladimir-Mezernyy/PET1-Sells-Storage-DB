-- ГЛАВА 6. НАПОЛНЕНИЕ ТЕСТОВЫМИ ДАННЫМИ 

-- (TODO: НОРМАЛИЗОВАТЬ ДОКУМЕНТАЦИЮ, СДЕЛАТЬ ПОЛНОЦЕННЫЕ ФУНКЦИИ НА ВВОД БОЛЬШОГО ЧИСЛА ДАННЫХ)

-- Сброс логов
TRUNCATE TABLE admin.action_logs, admin.error_logs RESTART IDENTITY;

-----------------------------------------

-- НАПОЛНЕНИЕ СХЕМЫ storage

-- Очистка от мусора схемы storage
TRUNCATE TABLE storage.product_batches, /*storage.product_suppliers, storage.suppliers,*/ storage.products, storage.categories RESTART IDENTITY;

-- Наполнение категориями
INSERT INTO storage.categories (name) VALUES
('Смартфоны'),
('Планшеты'),
('Ноутбуки'),
('Наушники');

-- Наполнение таблицы supplyiers (ВЫРЕЗАНО!)
 /* INSERT INTO storage.suppliers (name, contact_info) VALUES
('Поставщик А', 'info@supplier-a.com'),
('Поставщик Б', 'info@supplier-b.com');*/

-- Наполнение пустыми товарами таблицы products
INSERT INTO storage.products (name, category_id, description, total_quantity, reserved_quantity) VALUES
('Смартфон 1', 1, '', 0, 0),
('Смартфон 2', 1, '', 0, 0),
('Смартфон 3', 1, '', 0, 0),
('Смартфон 4', 1, '', 0, 0),
('Планшет 1', 2, '', 0, 0),
('Планшет 2', 2, '', 0, 0),
('Планшет 3', 2, '', 0, 0),
('Планшет 4', 2, '', 0, 0),
('Ноутбук 1', 3, '', 0, 0),
('Ноутбук 2', 3, '', 0, 0),
('Ноутбук 3', 3, '', 0, 0),
('Ноутбук 4', 3, '', 0, 0),
('Наушники 1', 4, '', 0, 0),
('Наушники 2', 4, '', 0, 0),
('Наушники 3', 4, '', 0, 0),
('Наушники 4', 4, '', 0, 0);

-- Наполнение product_suppliers (ВЫРЕЗАНО!)
/*INSERT INTO storage.product_suppliers (product_id, supplier_id) VALUES
-- Поставщик А
(1, 1), (2, 1), (3, 1), (4, 1),  -- Смартфоны
(5, 1), (6, 1), (7, 1), (8, 1),  -- Планшеты
(9, 1), (10, 1), (11, 1), (12, 1),  -- Ноутбуки
(13, 1), (14, 1), (15, 1), (16, 1),  -- Наушники
-- Поставщик Б
(1, 2), (2, 2), (3, 2), (4, 2),
(5, 2), (6, 2), (7, 2), (8, 2),
(9, 2), (10, 2), (11, 2), (12, 2),
(13, 2), (14, 2), (15, 2), (16, 2);*/

-- Наполнение таблиц product_batches и, исходя из product_batches, наполнение products
DO $$
DECLARE
    product RECORD;
    random_purchase_price DECIMAL(10, 2);
    random_selling_price DECIMAL(10, 2);
    random_quantity INT;
    random_arrival_date DATE;
BEGIN
	FOR i in 1..2 LOOP
	    FOR product IN (SELECT product_id FROM storage.products) LOOP
	        random_purchase_price := (RANDOM() * 40000 + 10000)::DECIMAL(10, 2);
	        random_selling_price := random_purchase_price * (1 + (RANDOM() * 0.2 + 0.1));
	        random_quantity := (RANDOM() * 90 + 10)::INT; 
	        random_arrival_date := NOW() - (RANDOM() * 365 || ' days')::INTERVAL;
	
	        INSERT INTO storage.product_batches (product_id, purchase_price, selling_price, quantity, arrival_date)
	        VALUES (product.product_id, random_purchase_price, random_selling_price, random_quantity, random_arrival_date);
	
	        UPDATE storage.products
	        SET total_quantity = total_quantity + random_quantity,
	            reserved_quantity = total_quantity * (RANDOM() * 0.2 + 0.2)
	        WHERE product_id = product.product_id;
	    END LOOP;
	END LOOP;
END $$;

-----------------------------------------

-- НАПОЛНЕНИЕ СХЕМЫ sales

-- Предварительная очистка мусора
TRUNCATE TABLE sales.customers, sales.order_items, sales.orders RESTART IDENTITY;

-- Создание клиентов
INSERT INTO sales.customers (name, email) VALUES
('Иван Иванов', 'ivan@example.com'),
('Петр Петров', 'petr@example.com'),
('Мария Марьевна', 'maria@example.com'),
('Владимир Мезерный', 'vovamez.work@example.com');

-- Создание заказов
INSERT INTO sales.orders (customer_id, order_date, status, shipping_address) VALUES
(1, '2024-10-25', 'оформлен', 'ул. Пример 1'),
(2, '2024-11-15', 'оплачен', 'ул. Пример 2'),
(3, '2024-11-10', 'доставлен', 'ул. Пример 3'),
(4, '2024-12-05', 'оформлен', 'ул. Пример 4'),
(1, '2024-12-20', 'оплачен', 'ул. Пример 1'),
(2, '2024-01-01', 'доставлен', 'ул. Пример 2'),
(3, '2025-01-10', 'отменён', 'ул. Пример 3');

-- Наполнение заказов товарами
INSERT INTO sales.order_items (order_id, product_id, quantity, price) VALUES
(1, 1, 2, 25000.00),
(1, 5, 1, 40000.00),
(2, 9, 1, 80000.00),
(2, 13, 2, 5000.00),
(3, 3, 1, 30000.00),
(3, 7, 1, 45000.00),
(4, 11, 1, 90000.00),
(4, 15, 3, 7000.00),
(5, 2, 1, 27000.00),
(5, 6, 2, 42000.00),
(6, 10, 1, 85000.00),
(6, 14, 1, 6000.00), 
(7, 4, 1, 32000.00),
(7, 8, 1, 47000.00);


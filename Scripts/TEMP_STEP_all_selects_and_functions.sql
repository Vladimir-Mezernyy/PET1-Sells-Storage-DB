/*select * from storage.categories c;
--select * from storage.suppliers s;
select * from storage.products p ;
--select * from storage.product_suppliers ps ;
select * from storage.product_batches pb ;
select * from sales.customers c ;
select * from sales.order_items oi ;
select * from sales.orders o ;
select * from storage.storage_data_view;
select * from sales.sales_finance_data_view;*/

--SELECT * FROM storage.get_all_suppliers(); ВЫРЕЗАНО!
SELECT * FROM sales.get_all_customers();
SELECT * FROM sales.get_all_orders();
SELECT * FROM sales.get_all_order_items();
SELECT * FROM storage.get_all_categories();
SELECT * FROM storage.get_all_products();
SELECT * FROM storage.get_all_batches();

SELECT * FROM sales.get_top_5_products_by_sales();
SELECT * FROM sales.get_avg_revenue_by_category_last_month();
SELECT * FROM storage.get_low_stock_products(80);
SELECT * FROM sales.get_orders_by_month();
SELECT * FROM storage.get_storage_data();
SELECT * FROM sales.get_finance_data();
SELECT * FROM sales.get_product_revenue_summary()

SELECT * FROM sales.get_3_month_moving_avg_revenue();
SELECT * FROM sales.get_top_profitable_products_by_category();
SELECT * FROM sales.get_loyal_customers();

/*SELECT add_supplier('Новый поставщик', 'info@new-supplier.com'); ВЫЗЕРАНО!
SELECT update_supplier(1, 'Обновлённый поставщик', 'new-info@supplier.com');
SELECT delete_supplier(1);
*/

SELECT storage.add_category('Новая категория');
SELECT storage.update_category(5, 'Обновлённая категория 2');
SELECT storage.delete_category(5);

SELECT storage.add_product('Новый товар', 1, 'Описание нового товара', 100, 10);
SELECT storage.update_product(17, 'Обновлённый товар', 2, 'Новое описание', 150, 20);
SELECT storage.delete_product(17);

SELECT * FROM storage.add_product_batch(1, 10000.00, 15000.00, 50, '2023-10-01');
SELECT * FROM storage.update_product_batch(33, 2, 12000.00, 18000.00, 60, '2023-10-05');
SELECT * FROM storage.delete_product_batch(33);

SELECT * FROM sales.add_customer('Новый клиент', 'new-customer@example.com');
SELECT * FROM sales.update_customer(5, 'Обновлённый клиент', 'updated-customer@example.com');
SELECT * FROM sales.delete_customer(5);

SELECT * FROM sales.add_order(1, CURRENT_DATE, 'оформлен', 'ул. Ленина, д. 10');
SELECT * FROM sales.update_order(8, 2, CURRENT_DATE, 'отменён', 'ул. Ленина, д. 15');
SELECT * FROM sales.delete_order(8);

SELECT * FROM sales.add_order_item(1, 1, 2, 25000.00);
SELECT * FROM sales.update_order_item(15, 2, 2, 3, 30000.00);
SELECT * FROM sales.delete_order_item(15);

SELECT * FROM admin.action_logs;
SELECT * FROM admin.error_logs;

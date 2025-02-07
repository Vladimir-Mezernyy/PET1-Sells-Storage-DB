--
-- PostgreSQL database cluster dump
--

-- Started on 2025-02-07 14:07:10

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;

--
-- User Configurations
--








--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-02-07 14:07:11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Completed on 2025-02-07 14:07:11

--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-02-07 14:07:11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 13 (class 2615 OID 63726)
-- Name: admin; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA admin;


ALTER SCHEMA admin OWNER TO postgres;

--
-- TOC entry 6 (class 2615 OID 16387)
-- Name: pgagent; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pgagent;


ALTER SCHEMA pgagent OWNER TO postgres;

--
-- TOC entry 5075 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA pgagent; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA pgagent IS 'pgAgent system tables';


--
-- TOC entry 12 (class 2615 OID 63684)
-- Name: sales; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA sales;


ALTER SCHEMA sales OWNER TO postgres;

--
-- TOC entry 11 (class 2615 OID 63638)
-- Name: storage; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA storage;


ALTER SCHEMA storage OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 16388)
-- Name: pgagent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgagent WITH SCHEMA pgagent;


--
-- TOC entry 5076 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgagent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgagent IS 'A PostgreSQL job scheduler';


--
-- TOC entry 310 (class 1255 OID 63803)
-- Name: log_all_changes_and_errors(); Type: FUNCTION; Schema: admin; Owner: postgres
--

CREATE FUNCTION admin.log_all_changes_and_errors() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION admin.log_all_changes_and_errors() OWNER TO postgres;

--
-- TOC entry 301 (class 1255 OID 63794)
-- Name: add_customer(character varying, character varying); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.add_customer(customer_name character varying, new_email character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_customer_id INT;
BEGIN
    INSERT INTO sales.customers (name, email)
    VALUES (customer_name, new_email)
    RETURNING customer_id INTO new_customer_id;

    RETURN new_customer_id;
END;
$$;


ALTER FUNCTION sales.add_customer(customer_name character varying, new_email character varying) OWNER TO postgres;

--
-- TOC entry 304 (class 1255 OID 63797)
-- Name: add_order(integer, date, character varying, text); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.add_order(id integer, new_date date, new_status character varying, new_shipping_address text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_order_id INT;
BEGIN
    INSERT INTO sales.orders (customer_id, order_date, status, shipping_address)
    VALUES (id, new_date, new_status, new_shipping_address)
    RETURNING order_id INTO new_order_id;

    RETURN new_order_id;
END;
$$;


ALTER FUNCTION sales.add_order(id integer, new_date date, new_status character varying, new_shipping_address text) OWNER TO postgres;

--
-- TOC entry 307 (class 1255 OID 63800)
-- Name: add_order_item(integer, integer, integer, numeric); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.add_order_item(new_order_id integer, new_product_id integer, new_quantity integer, new_price numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_order_item_id INT;
BEGIN
    INSERT INTO sales.order_items (order_id, product_id, quantity, price)
    VALUES (new_order_id, new_product_id, new_quantity, new_price)    
	RETURNING order_item_id INTO new_order_item_id;

    RETURN new_order_item_id;
END;
$$;


ALTER FUNCTION sales.add_order_item(new_order_id integer, new_product_id integer, new_quantity integer, new_price numeric) OWNER TO postgres;

--
-- TOC entry 312 (class 1255 OID 63812)
-- Name: check_product_availability(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.check_product_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION sales.check_product_availability() OWNER TO postgres;

--
-- TOC entry 303 (class 1255 OID 63796)
-- Name: delete_customer(integer); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.delete_customer(id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM sales.customers
    WHERE customer_id = delete_customer.id;
END;
$$;


ALTER FUNCTION sales.delete_customer(id integer) OWNER TO postgres;

--
-- TOC entry 306 (class 1255 OID 63799)
-- Name: delete_order(integer); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.delete_order(id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM sales.orders
    WHERE order_id = delete_order.id;
END;
$$;


ALTER FUNCTION sales.delete_order(id integer) OWNER TO postgres;

--
-- TOC entry 309 (class 1255 OID 63802)
-- Name: delete_order_item(integer); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.delete_order_item(id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM sales.order_items
    WHERE order_item_id = delete_order_item.id;
END;
$$;


ALTER FUNCTION sales.delete_order_item(id integer) OWNER TO postgres;

--
-- TOC entry 289 (class 1255 OID 63782)
-- Name: get_3_month_moving_avg_revenue(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_3_month_moving_avg_revenue() RETURNS TABLE("Месяц" text, "Выручка" numeric, "Скользящее среднее" numeric)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION sales.get_3_month_moving_avg_revenue() OWNER TO postgres;

--
-- TOC entry 276 (class 1255 OID 63769)
-- Name: get_all_customers(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_all_customers() RETURNS TABLE(customer_id integer, name character varying, email character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c.customer_id, c.name, c.email
    FROM sales.customers c
	ORDER BY 1;
END;
$$;


ALTER FUNCTION sales.get_all_customers() OWNER TO postgres;

--
-- TOC entry 278 (class 1255 OID 63771)
-- Name: get_all_order_items(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_all_order_items() RETURNS TABLE(order_item_id integer, order_id integer, product_id integer, quantity integer, price numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT oi.order_item_id, oi.order_id, oi.product_id, oi.quantity, oi.price
    FROM sales.order_items oi
    ORDER BY 2, 1, 3;
END;
$$;


ALTER FUNCTION sales.get_all_order_items() OWNER TO postgres;

--
-- TOC entry 277 (class 1255 OID 63770)
-- Name: get_all_orders(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_all_orders() RETURNS TABLE(order_id integer, customer_id integer, order_date date, status character varying, shipping_address text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.customer_id, o.order_date, o.status, o.shipping_address
    FROM sales.orders o
    ORDER BY 1;
END;
$$;


ALTER FUNCTION sales.get_all_orders() OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 63776)
-- Name: get_avg_revenue_by_category_last_month(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_avg_revenue_by_category_last_month() RETURNS TABLE(category_name character varying, avg_revenue numeric)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION sales.get_avg_revenue_by_category_last_month() OWNER TO postgres;

--
-- TOC entry 287 (class 1255 OID 63780)
-- Name: get_finance_data(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_finance_data() RETURNS TABLE("Идентификатор заказа" integer, "Дата заказа" date, "Клиент" character varying, "Выручка" numeric, "Себестоимость" numeric, "Прибыль" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM sales.sales_finance_data_view;
END;
$$;


ALTER FUNCTION sales.get_finance_data() OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 63784)
-- Name: get_loyal_customers(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_loyal_customers() RETURNS TABLE("ID клиента" integer, "Имя клиента" character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION sales.get_loyal_customers() OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 63778)
-- Name: get_orders_by_month(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_orders_by_month() RETURNS TABLE(month text, order_count integer)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION sales.get_orders_by_month() OWNER TO postgres;

--
-- TOC entry 288 (class 1255 OID 63781)
-- Name: get_product_revenue_summary(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_product_revenue_summary() RETURNS TABLE("Идентификатор товара" integer, "Название товара" character varying, "Категория" character varying, "Суммарная выручка" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM sales.product_revenue_summary;
END;
$$;


ALTER FUNCTION sales.get_product_revenue_summary() OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 63775)
-- Name: get_top_5_products_by_sales(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_top_5_products_by_sales() RETURNS TABLE(product_id integer, product_name character varying, total_sales integer)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION sales.get_top_5_products_by_sales() OWNER TO postgres;

--
-- TOC entry 290 (class 1255 OID 63783)
-- Name: get_top_profitable_products_by_category(); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.get_top_profitable_products_by_category() RETURNS TABLE("Название категории" character varying, "Название продукта" character varying, "Суммарная выручка" numeric)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION sales.get_top_profitable_products_by_category() OWNER TO postgres;

--
-- TOC entry 302 (class 1255 OID 63795)
-- Name: update_customer(integer, character varying, character varying); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.update_customer(id integer, new_name character varying, new_email character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE sales.customers
    SET name = new_name,
        email = new_email
    WHERE customer_id = update_customer.id;
END;
$$;


ALTER FUNCTION sales.update_customer(id integer, new_name character varying, new_email character varying) OWNER TO postgres;

--
-- TOC entry 305 (class 1255 OID 63798)
-- Name: update_order(integer, integer, date, character varying, text); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.update_order(id integer, new_customer_id integer, new_order_date date, new_status character varying, new_shipping_address text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE sales.orders
    SET customer_id = new_customer_id,
		order_date = new_order_date,
		status = new_status,
        shipping_address = new_shipping_address
    WHERE order_id = update_order.id;
END;
$$;


ALTER FUNCTION sales.update_order(id integer, new_customer_id integer, new_order_date date, new_status character varying, new_shipping_address text) OWNER TO postgres;

--
-- TOC entry 308 (class 1255 OID 63801)
-- Name: update_order_item(integer, integer, integer, integer, numeric); Type: FUNCTION; Schema: sales; Owner: postgres
--

CREATE FUNCTION sales.update_order_item(id integer, new_order_id integer, new_product_id integer, new_quantity integer, new_price numeric) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE sales.order_items
    SET order_id = new_order_id,
        product_id = new_product_id,
        quantity = new_quantity,
        price = new_price
    WHERE order_item_id = update_order_item.id;
END;
$$;


ALTER FUNCTION sales.update_order_item(id integer, new_order_id integer, new_product_id integer, new_quantity integer, new_price numeric) OWNER TO postgres;

--
-- TOC entry 292 (class 1255 OID 63785)
-- Name: add_category(character varying); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.add_category(category_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_category_id INT;
BEGIN
    INSERT INTO storage.categories (name)
    VALUES (category_name)
    RETURNING category_id INTO new_category_id;

    RETURN new_category_id;
END;
$$;


ALTER FUNCTION storage.add_category(category_name character varying) OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 63788)
-- Name: add_product(character varying, integer, text, integer, integer); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.add_product(product_name character varying, id integer, descr text, t_quantity integer, r_quantity integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_product_id INT;
BEGIN
    INSERT INTO storage.products (name, category_id, description, total_quantity, reserved_quantity)
    VALUES (product_name, id, descr, t_quantity, r_quantity)
    RETURNING product_id INTO new_product_id;

    RETURN new_product_id;
END;
$$;


ALTER FUNCTION storage.add_product(product_name character varying, id integer, descr text, t_quantity integer, r_quantity integer) OWNER TO postgres;

--
-- TOC entry 298 (class 1255 OID 63791)
-- Name: add_product_batch(integer, numeric, numeric, integer, date); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.add_product_batch(id integer, p_price numeric, s_price numeric, quant integer, a_date date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_batch_id INT;
BEGIN
    INSERT INTO storage.product_batches (product_id, /*supplier_id,*/ purchase_price, selling_price, quantity, arrival_date)
    VALUES (id, /*supplier_id,*/ p_price, s_price, quant, a_date)
    RETURNING batch_id INTO new_batch_id;

    RETURN new_batch_id;
END;
$$;


ALTER FUNCTION storage.add_product_batch(id integer, p_price numeric, s_price numeric, quant integer, a_date date) OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 63787)
-- Name: delete_category(integer); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.delete_category(id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM storage.categories
    WHERE category_id = delete_category.id;
END;
$$;


ALTER FUNCTION storage.delete_category(id integer) OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 63790)
-- Name: delete_product(integer); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.delete_product(id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM storage.products
    WHERE product_id = delete_product.id;
END;
$$;


ALTER FUNCTION storage.delete_product(id integer) OWNER TO postgres;

--
-- TOC entry 300 (class 1255 OID 63793)
-- Name: delete_product_batch(integer); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.delete_product_batch(id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM storage.product_batches
    WHERE batch_id = delete_product_batch.id;
END;
$$;


ALTER FUNCTION storage.delete_product_batch(id integer) OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 63774)
-- Name: get_all_batches(); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.get_all_batches() RETURNS TABLE(batch_id integer, product_id integer, purchase_price numeric, selling_price numeric, quantity integer, arrival_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT pb.batch_id, pb.product_id, /*pb_supplier_id,*/ pb.purchase_price, pb.selling_price, pb.quantity, pb.arrival_date
    FROM storage.product_batches pb
	ORDER BY 1, 2, 6;
END;
$$;


ALTER FUNCTION storage.get_all_batches() OWNER TO postgres;

--
-- TOC entry 279 (class 1255 OID 63772)
-- Name: get_all_categories(); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.get_all_categories() RETURNS TABLE(category_id integer, name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c.category_id, c.name
    FROM storage.categories c
	ORDER BY 1;
END;
$$;


ALTER FUNCTION storage.get_all_categories() OWNER TO postgres;

--
-- TOC entry 280 (class 1255 OID 63773)
-- Name: get_all_products(); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.get_all_products() RETURNS TABLE(product_id integer, name character varying, category_id integer, description text, total_quantity integer, reserved_quantity integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, p.category_id, p.description, p.total_quantity, p.reserved_quantity
    FROM storage.products p
	ORDER BY 3, 1;
END;
$$;


ALTER FUNCTION storage.get_all_products() OWNER TO postgres;

--
-- TOC entry 284 (class 1255 OID 63777)
-- Name: get_low_stock_products(integer); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.get_low_stock_products(threshold integer) RETURNS TABLE(product_id integer, product_name character varying, total_quantity integer, reserved_quantity integer, available_quantity integer)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION storage.get_low_stock_products(threshold integer) OWNER TO postgres;

--
-- TOC entry 286 (class 1255 OID 63779)
-- Name: get_storage_data(); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.get_storage_data() RETURNS TABLE("Идентификатор товара" integer, "Название товара" character varying, "Категория" character varying, "Общее количество" integer, "Зарезервировано" integer, "Доступно" integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM storage.storage_data_view;
END;
$$;


ALTER FUNCTION storage.get_storage_data() OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 63786)
-- Name: update_category(integer, character varying); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.update_category(id integer, new_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE storage.categories
    SET name = new_name
    WHERE category_id = update_category.id;
END;
$$;


ALTER FUNCTION storage.update_category(id integer, new_name character varying) OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 63789)
-- Name: update_product(integer, character varying, integer, text, integer, integer); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.update_product(id integer, new_name character varying, new_category_id integer, new_description text, new_total_quantity integer, new_reserved_quantity integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE storage.products
    SET name = new_name,
        category_id = new_category_id,
        description = new_description,
        total_quantity = new_total_quantity,
        reserved_quantity = new_reserved_quantity
    WHERE product_id = update_product.id;
END;
$$;


ALTER FUNCTION storage.update_product(id integer, new_name character varying, new_category_id integer, new_description text, new_total_quantity integer, new_reserved_quantity integer) OWNER TO postgres;

--
-- TOC entry 299 (class 1255 OID 63792)
-- Name: update_product_batch(integer, integer, numeric, numeric, integer, date); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.update_product_batch(id integer, new_product_id integer, new_purchase_price numeric, new_selling_price numeric, new_quantity integer, new_arrival_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION storage.update_product_batch(id integer, new_product_id integer, new_purchase_price numeric, new_selling_price numeric, new_quantity integer, new_arrival_date date) OWNER TO postgres;

--
-- TOC entry 311 (class 1255 OID 63810)
-- Name: update_total_quantity(); Type: FUNCTION; Schema: storage; Owner: postgres
--

CREATE FUNCTION storage.update_total_quantity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE storage.products
    SET total_quantity = total_quantity + NEW.quantity
    WHERE product_id = NEW.product_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION storage.update_total_quantity() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 253 (class 1259 OID 63728)
-- Name: action_logs; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.action_logs (
    action_id integer NOT NULL,
    action_type character varying(50) NOT NULL,
    table_name character varying(50) NOT NULL,
    record_id integer,
    action_details jsonb,
    action_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_id integer DEFAULT 1
);


ALTER TABLE admin.action_logs OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 63727)
-- Name: action_logs_action_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.action_logs_action_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.action_logs_action_id_seq OWNER TO postgres;

--
-- TOC entry 5077 (class 0 OID 0)
-- Dependencies: 252
-- Name: action_logs_action_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.action_logs_action_id_seq OWNED BY admin.action_logs.action_id;


--
-- TOC entry 255 (class 1259 OID 63743)
-- Name: error_logs; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.error_logs (
    error_id integer NOT NULL,
    error_message text NOT NULL,
    error_details jsonb,
    error_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_id integer DEFAULT 1
);


ALTER TABLE admin.error_logs OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 63742)
-- Name: error_logs_error_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.error_logs_error_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.error_logs_error_id_seq OWNER TO postgres;

--
-- TOC entry 5078 (class 0 OID 0)
-- Dependencies: 254
-- Name: error_logs_error_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.error_logs_error_id_seq OWNED BY admin.error_logs.error_id;


--
-- TOC entry 247 (class 1259 OID 63686)
-- Name: customers; Type: TABLE; Schema: sales; Owner: postgres
--

CREATE TABLE sales.customers (
    customer_id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL
);


ALTER TABLE sales.customers OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 63685)
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: sales; Owner: postgres
--

CREATE SEQUENCE sales.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE sales.customers_customer_id_seq OWNER TO postgres;

--
-- TOC entry 5079 (class 0 OID 0)
-- Dependencies: 246
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: sales; Owner: postgres
--

ALTER SEQUENCE sales.customers_customer_id_seq OWNED BY sales.customers.customer_id;


--
-- TOC entry 251 (class 1259 OID 63713)
-- Name: order_items; Type: TABLE; Schema: sales; Owner: postgres
--

CREATE TABLE sales.order_items (
    order_item_id integer NOT NULL,
    order_id integer,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    price numeric(10,2) NOT NULL,
    CONSTRAINT order_items_price_check CHECK ((price > (0)::numeric)),
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE sales.order_items OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 63712)
-- Name: order_items_order_item_id_seq; Type: SEQUENCE; Schema: sales; Owner: postgres
--

CREATE SEQUENCE sales.order_items_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE sales.order_items_order_item_id_seq OWNER TO postgres;

--
-- TOC entry 5080 (class 0 OID 0)
-- Dependencies: 250
-- Name: order_items_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: sales; Owner: postgres
--

ALTER SEQUENCE sales.order_items_order_item_id_seq OWNED BY sales.order_items.order_item_id;


--
-- TOC entry 249 (class 1259 OID 63697)
-- Name: orders; Type: TABLE; Schema: sales; Owner: postgres
--

CREATE TABLE sales.orders (
    order_id integer NOT NULL,
    customer_id integer,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(50) NOT NULL,
    shipping_address text NOT NULL,
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY ((ARRAY['оформлен'::character varying, 'оплачен'::character varying, 'доставлен'::character varying, 'отменён'::character varying])::text[])))
);


ALTER TABLE sales.orders OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 63696)
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: sales; Owner: postgres
--

CREATE SEQUENCE sales.orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE sales.orders_order_id_seq OWNER TO postgres;

--
-- TOC entry 5081 (class 0 OID 0)
-- Dependencies: 248
-- Name: orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: sales; Owner: postgres
--

ALTER SEQUENCE sales.orders_order_id_seq OWNED BY sales.orders.order_id;


--
-- TOC entry 241 (class 1259 OID 63640)
-- Name: categories; Type: TABLE; Schema: storage; Owner: postgres
--

CREATE TABLE storage.categories (
    category_id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE storage.categories OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 63669)
-- Name: product_batches; Type: TABLE; Schema: storage; Owner: postgres
--

CREATE TABLE storage.product_batches (
    batch_id integer NOT NULL,
    product_id integer,
    purchase_price numeric(10,2) NOT NULL,
    selling_price numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    arrival_date date NOT NULL,
    CONSTRAINT product_batches_arrival_date_check CHECK ((arrival_date <= CURRENT_DATE)),
    CONSTRAINT product_batches_check CHECK ((selling_price >= purchase_price)),
    CONSTRAINT product_batches_purchase_price_check CHECK ((purchase_price > (0)::numeric)),
    CONSTRAINT product_batches_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE storage.product_batches OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 63649)
-- Name: products; Type: TABLE; Schema: storage; Owner: postgres
--

CREATE TABLE storage.products (
    product_id integer NOT NULL,
    name character varying(255) NOT NULL,
    category_id integer,
    description text,
    total_quantity integer DEFAULT 0 NOT NULL,
    reserved_quantity integer DEFAULT 0 NOT NULL,
    CONSTRAINT products_check CHECK ((reserved_quantity <= total_quantity)),
    CONSTRAINT products_total_quantity_check CHECK ((total_quantity >= 0))
);


ALTER TABLE storage.products OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 63764)
-- Name: product_revenue_summary; Type: VIEW; Schema: sales; Owner: postgres
--

CREATE VIEW sales.product_revenue_summary AS
 SELECT p.product_id AS "Идентификатор товара",
    p.name AS "Название товара",
    c.name AS "Категория",
    sum((oi.price - pb.purchase_price)) AS "Суммарная выручка"
   FROM (((sales.order_items oi
     JOIN storage.products p ON ((oi.product_id = p.product_id)))
     JOIN storage.categories c ON ((p.category_id = c.category_id)))
     JOIN storage.product_batches pb ON ((oi.product_id = pb.product_id)))
  GROUP BY p.product_id, p.name, c.name
  ORDER BY p.product_id, c.name;


ALTER VIEW sales.product_revenue_summary OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 63759)
-- Name: sales_finance_data_view; Type: VIEW; Schema: sales; Owner: postgres
--

CREATE VIEW sales.sales_finance_data_view AS
 SELECT o.order_id AS "Идентификатор заказа",
    o.order_date AS "Дата заказа",
    c.name AS "Клиент",
    sum(((oi.quantity)::numeric * oi.price)) AS "Выручка",
    sum(((oi.quantity)::numeric * pb.purchase_price)) AS "Себестоимость",
    (sum(((oi.quantity)::numeric * oi.price)) - sum(((oi.quantity)::numeric * pb.purchase_price))) AS "Прибыль"
   FROM (((sales.orders o
     JOIN sales.order_items oi ON ((o.order_id = oi.order_id)))
     JOIN storage.product_batches pb ON ((oi.product_id = pb.product_id)))
     JOIN sales.customers c ON ((o.customer_id = c.customer_id)))
  GROUP BY o.order_id, o.order_date, c.name
  ORDER BY o.order_date, c.name, o.order_id;


ALTER VIEW sales.sales_finance_data_view OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 63639)
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: storage; Owner: postgres
--

CREATE SEQUENCE storage.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE storage.categories_category_id_seq OWNER TO postgres;

--
-- TOC entry 5082 (class 0 OID 0)
-- Dependencies: 240
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: storage; Owner: postgres
--

ALTER SEQUENCE storage.categories_category_id_seq OWNED BY storage.categories.category_id;


--
-- TOC entry 244 (class 1259 OID 63668)
-- Name: product_batches_batch_id_seq; Type: SEQUENCE; Schema: storage; Owner: postgres
--

CREATE SEQUENCE storage.product_batches_batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE storage.product_batches_batch_id_seq OWNER TO postgres;

--
-- TOC entry 5083 (class 0 OID 0)
-- Dependencies: 244
-- Name: product_batches_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: storage; Owner: postgres
--

ALTER SEQUENCE storage.product_batches_batch_id_seq OWNED BY storage.product_batches.batch_id;


--
-- TOC entry 242 (class 1259 OID 63648)
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: storage; Owner: postgres
--

CREATE SEQUENCE storage.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE storage.products_product_id_seq OWNER TO postgres;

--
-- TOC entry 5084 (class 0 OID 0)
-- Dependencies: 242
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: storage; Owner: postgres
--

ALTER SEQUENCE storage.products_product_id_seq OWNED BY storage.products.product_id;


--
-- TOC entry 256 (class 1259 OID 63755)
-- Name: storage_data_view; Type: VIEW; Schema: storage; Owner: postgres
--

CREATE VIEW storage.storage_data_view AS
SELECT
    NULL::integer AS "Идентификатор товара",
    NULL::character varying(255) AS "Название товара",
    NULL::character varying(255) AS "Категория",
    NULL::integer AS "Общее количество",
    NULL::integer AS "Зарезервировано",
    NULL::integer AS "Доступно";


ALTER VIEW storage.storage_data_view OWNER TO postgres;

--
-- TOC entry 4817 (class 2604 OID 63731)
-- Name: action_logs action_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.action_logs ALTER COLUMN action_id SET DEFAULT nextval('admin.action_logs_action_id_seq'::regclass);


--
-- TOC entry 4820 (class 2604 OID 63746)
-- Name: error_logs error_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.error_logs ALTER COLUMN error_id SET DEFAULT nextval('admin.error_logs_error_id_seq'::regclass);


--
-- TOC entry 4813 (class 2604 OID 63689)
-- Name: customers customer_id; Type: DEFAULT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.customers ALTER COLUMN customer_id SET DEFAULT nextval('sales.customers_customer_id_seq'::regclass);


--
-- TOC entry 4816 (class 2604 OID 63716)
-- Name: order_items order_item_id; Type: DEFAULT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.order_items ALTER COLUMN order_item_id SET DEFAULT nextval('sales.order_items_order_item_id_seq'::regclass);


--
-- TOC entry 4814 (class 2604 OID 63700)
-- Name: orders order_id; Type: DEFAULT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.orders ALTER COLUMN order_id SET DEFAULT nextval('sales.orders_order_id_seq'::regclass);


--
-- TOC entry 4808 (class 2604 OID 63643)
-- Name: categories category_id; Type: DEFAULT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.categories ALTER COLUMN category_id SET DEFAULT nextval('storage.categories_category_id_seq'::regclass);


--
-- TOC entry 4812 (class 2604 OID 63672)
-- Name: product_batches batch_id; Type: DEFAULT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.product_batches ALTER COLUMN batch_id SET DEFAULT nextval('storage.product_batches_batch_id_seq'::regclass);


--
-- TOC entry 4809 (class 2604 OID 63652)
-- Name: products product_id; Type: DEFAULT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.products ALTER COLUMN product_id SET DEFAULT nextval('storage.products_product_id_seq'::regclass);


--
-- TOC entry 5067 (class 0 OID 63728)
-- Dependencies: 253
-- Data for Name: action_logs; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.action_logs (action_id, action_type, table_name, record_id, action_details, action_time, user_id) FROM stdin;
1	INSERT	categories	1	{"new": {"name": "Смартфоны", "category_id": 1}, "old": null}	2025-02-07 12:59:31.398138	1
2	INSERT	categories	2	{"new": {"name": "Планшеты", "category_id": 2}, "old": null}	2025-02-07 12:59:31.398138	1
3	INSERT	categories	3	{"new": {"name": "Ноутбуки", "category_id": 3}, "old": null}	2025-02-07 12:59:31.398138	1
4	INSERT	categories	4	{"new": {"name": "Наушники", "category_id": 4}, "old": null}	2025-02-07 12:59:31.398138	1
5	INSERT	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
6	INSERT	products	2	{"new": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
7	INSERT	products	3	{"new": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
8	INSERT	products	4	{"new": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
9	INSERT	products	5	{"new": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
10	INSERT	products	6	{"new": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
11	INSERT	products	7	{"new": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
12	INSERT	products	8	{"new": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
13	INSERT	products	9	{"new": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
14	INSERT	products	10	{"new": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
15	INSERT	products	11	{"new": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
16	INSERT	products	12	{"new": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
17	INSERT	products	13	{"new": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
18	INSERT	products	14	{"new": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
19	INSERT	products	15	{"new": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
20	INSERT	products	16	{"new": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}, "old": null}	2025-02-07 12:59:31.429149	1
21	INSERT	product_batches	1	{"new": {"batch_id": 1, "quantity": 41, "product_id": 1, "arrival_date": "2024-02-11", "selling_price": 49379.49, "purchase_price": 41861.91}, "old": null}	2025-02-07 12:59:31.446596	1
22	UPDATE	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 41, "reserved_quantity": 0}, "old": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
23	UPDATE	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 82, "reserved_quantity": 16}, "old": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 41, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
24	INSERT	product_batches	2	{"new": {"batch_id": 2, "quantity": 42, "product_id": 2, "arrival_date": "2025-01-27", "selling_price": 50738.55, "purchase_price": 43870.46}, "old": null}	2025-02-07 12:59:31.446596	1
25	UPDATE	products	2	{"new": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 42, "reserved_quantity": 0}, "old": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
26	UPDATE	products	2	{"new": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 84, "reserved_quantity": 15}, "old": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 42, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
27	INSERT	product_batches	3	{"new": {"batch_id": 3, "quantity": 70, "product_id": 3, "arrival_date": "2024-12-09", "selling_price": 27277.69, "purchase_price": 22659.61}, "old": null}	2025-02-07 12:59:31.446596	1
28	UPDATE	products	3	{"new": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 70, "reserved_quantity": 0}, "old": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
29	UPDATE	products	3	{"new": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 140, "reserved_quantity": 18}, "old": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 70, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
30	INSERT	product_batches	4	{"new": {"batch_id": 4, "quantity": 46, "product_id": 4, "arrival_date": "2024-04-06", "selling_price": 18557.47, "purchase_price": 14454.17}, "old": null}	2025-02-07 12:59:31.446596	1
31	UPDATE	products	4	{"new": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 46, "reserved_quantity": 0}, "old": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
32	UPDATE	products	4	{"new": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 92, "reserved_quantity": 15}, "old": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 46, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
33	INSERT	product_batches	5	{"new": {"batch_id": 5, "quantity": 26, "product_id": 5, "arrival_date": "2024-09-07", "selling_price": 43791.27, "purchase_price": 34070.90}, "old": null}	2025-02-07 12:59:31.446596	1
34	UPDATE	products	5	{"new": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 26, "reserved_quantity": 0}, "old": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
35	UPDATE	products	5	{"new": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 52, "reserved_quantity": 6}, "old": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 26, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
36	INSERT	product_batches	6	{"new": {"batch_id": 6, "quantity": 56, "product_id": 6, "arrival_date": "2024-03-28", "selling_price": 24953.77, "purchase_price": 20337.69}, "old": null}	2025-02-07 12:59:31.446596	1
37	UPDATE	products	6	{"new": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 56, "reserved_quantity": 0}, "old": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
38	UPDATE	products	6	{"new": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 112, "reserved_quantity": 16}, "old": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 56, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
39	INSERT	product_batches	7	{"new": {"batch_id": 7, "quantity": 61, "product_id": 7, "arrival_date": "2024-04-20", "selling_price": 50626.94, "purchase_price": 39303.79}, "old": null}	2025-02-07 12:59:31.446596	1
40	UPDATE	products	7	{"new": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 61, "reserved_quantity": 0}, "old": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
41	UPDATE	products	7	{"new": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 122, "reserved_quantity": 22}, "old": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 61, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
42	INSERT	product_batches	8	{"new": {"batch_id": 8, "quantity": 99, "product_id": 8, "arrival_date": "2024-06-04", "selling_price": 17944.48, "purchase_price": 15191.73}, "old": null}	2025-02-07 12:59:31.446596	1
43	UPDATE	products	8	{"new": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 99, "reserved_quantity": 0}, "old": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
44	UPDATE	products	8	{"new": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 198, "reserved_quantity": 31}, "old": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 99, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
45	INSERT	product_batches	9	{"new": {"batch_id": 9, "quantity": 32, "product_id": 9, "arrival_date": "2024-05-24", "selling_price": 37563.41, "purchase_price": 29352.61}, "old": null}	2025-02-07 12:59:31.446596	1
46	UPDATE	products	9	{"new": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 32, "reserved_quantity": 0}, "old": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
47	UPDATE	products	9	{"new": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 64, "reserved_quantity": 12}, "old": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 32, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
48	INSERT	product_batches	10	{"new": {"batch_id": 10, "quantity": 55, "product_id": 10, "arrival_date": "2024-08-21", "selling_price": 30898.82, "purchase_price": 25085.06}, "old": null}	2025-02-07 12:59:31.446596	1
69	INSERT	product_batches	17	{"new": {"batch_id": 17, "quantity": 61, "product_id": 1, "arrival_date": "2024-06-17", "selling_price": 40277.53, "purchase_price": 35523.34}, "old": null}	2025-02-07 12:59:31.446596	1
49	UPDATE	products	10	{"new": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 55, "reserved_quantity": 0}, "old": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
50	UPDATE	products	10	{"new": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 110, "reserved_quantity": 12}, "old": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 55, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
51	INSERT	product_batches	11	{"new": {"batch_id": 11, "quantity": 42, "product_id": 11, "arrival_date": "2024-11-06", "selling_price": 58982.42, "purchase_price": 49474.47}, "old": null}	2025-02-07 12:59:31.446596	1
52	UPDATE	products	11	{"new": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 42, "reserved_quantity": 0}, "old": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
53	UPDATE	products	11	{"new": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 84, "reserved_quantity": 12}, "old": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 42, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
54	INSERT	product_batches	12	{"new": {"batch_id": 12, "quantity": 19, "product_id": 12, "arrival_date": "2024-02-24", "selling_price": 53011.97, "purchase_price": 41729.64}, "old": null}	2025-02-07 12:59:31.446596	1
55	UPDATE	products	12	{"new": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 19, "reserved_quantity": 0}, "old": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
56	UPDATE	products	12	{"new": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 38, "reserved_quantity": 4}, "old": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 19, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
57	INSERT	product_batches	13	{"new": {"batch_id": 13, "quantity": 47, "product_id": 13, "arrival_date": "2024-10-28", "selling_price": 55764.91, "purchase_price": 48996.98}, "old": null}	2025-02-07 12:59:31.446596	1
58	UPDATE	products	13	{"new": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 47, "reserved_quantity": 0}, "old": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
59	UPDATE	products	13	{"new": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 94, "reserved_quantity": 16}, "old": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 47, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
60	INSERT	product_batches	14	{"new": {"batch_id": 14, "quantity": 32, "product_id": 14, "arrival_date": "2025-01-20", "selling_price": 16000.83, "purchase_price": 14222.66}, "old": null}	2025-02-07 12:59:31.446596	1
61	UPDATE	products	14	{"new": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 32, "reserved_quantity": 0}, "old": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
62	UPDATE	products	14	{"new": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 64, "reserved_quantity": 9}, "old": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 32, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
63	INSERT	product_batches	15	{"new": {"batch_id": 15, "quantity": 58, "product_id": 15, "arrival_date": "2024-08-09", "selling_price": 24734.00, "purchase_price": 22330.51}, "old": null}	2025-02-07 12:59:31.446596	1
64	UPDATE	products	15	{"new": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 58, "reserved_quantity": 0}, "old": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
65	UPDATE	products	15	{"new": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 116, "reserved_quantity": 13}, "old": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 58, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
66	INSERT	product_batches	16	{"new": {"batch_id": 16, "quantity": 25, "product_id": 16, "arrival_date": "2024-08-02", "selling_price": 35239.39, "purchase_price": 27708.61}, "old": null}	2025-02-07 12:59:31.446596	1
67	UPDATE	products	16	{"new": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 25, "reserved_quantity": 0}, "old": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 0, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
68	UPDATE	products	16	{"new": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 50, "reserved_quantity": 10}, "old": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 25, "reserved_quantity": 0}}	2025-02-07 12:59:31.446596	1
70	UPDATE	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 143, "reserved_quantity": 16}, "old": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 82, "reserved_quantity": 16}}	2025-02-07 12:59:31.446596	1
71	UPDATE	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 204, "reserved_quantity": 32}, "old": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 143, "reserved_quantity": 16}}	2025-02-07 12:59:31.446596	1
72	INSERT	product_batches	18	{"new": {"batch_id": 18, "quantity": 43, "product_id": 2, "arrival_date": "2024-10-30", "selling_price": 28862.60, "purchase_price": 23503.76}, "old": null}	2025-02-07 12:59:31.446596	1
73	UPDATE	products	2	{"new": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 127, "reserved_quantity": 15}, "old": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 84, "reserved_quantity": 15}}	2025-02-07 12:59:31.446596	1
74	UPDATE	products	2	{"new": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 170, "reserved_quantity": 40}, "old": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 127, "reserved_quantity": 15}}	2025-02-07 12:59:31.446596	1
75	INSERT	product_batches	19	{"new": {"batch_id": 19, "quantity": 82, "product_id": 3, "arrival_date": "2024-10-12", "selling_price": 60337.14, "purchase_price": 47656.24}, "old": null}	2025-02-07 12:59:31.446596	1
76	UPDATE	products	3	{"new": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 222, "reserved_quantity": 18}, "old": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 140, "reserved_quantity": 18}}	2025-02-07 12:59:31.446596	1
77	UPDATE	products	3	{"new": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 304, "reserved_quantity": 78}, "old": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 222, "reserved_quantity": 18}}	2025-02-07 12:59:31.446596	1
78	INSERT	product_batches	20	{"new": {"batch_id": 20, "quantity": 69, "product_id": 4, "arrival_date": "2024-09-11", "selling_price": 51055.50, "purchase_price": 39887.62}, "old": null}	2025-02-07 12:59:31.446596	1
79	UPDATE	products	4	{"new": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 161, "reserved_quantity": 15}, "old": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 92, "reserved_quantity": 15}}	2025-02-07 12:59:31.446596	1
80	UPDATE	products	4	{"new": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 230, "reserved_quantity": 60}, "old": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 161, "reserved_quantity": 15}}	2025-02-07 12:59:31.446596	1
81	INSERT	product_batches	21	{"new": {"batch_id": 21, "quantity": 14, "product_id": 5, "arrival_date": "2024-06-10", "selling_price": 46938.29, "purchase_price": 37065.92}, "old": null}	2025-02-07 12:59:31.446596	1
82	UPDATE	products	5	{"new": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 66, "reserved_quantity": 6}, "old": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 52, "reserved_quantity": 6}}	2025-02-07 12:59:31.446596	1
83	UPDATE	products	5	{"new": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 80, "reserved_quantity": 23}, "old": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 66, "reserved_quantity": 6}}	2025-02-07 12:59:31.446596	1
84	INSERT	product_batches	22	{"new": {"batch_id": 22, "quantity": 84, "product_id": 6, "arrival_date": "2024-04-07", "selling_price": 38523.72, "purchase_price": 34397.23}, "old": null}	2025-02-07 12:59:31.446596	1
85	UPDATE	products	6	{"new": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 196, "reserved_quantity": 16}, "old": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 112, "reserved_quantity": 16}}	2025-02-07 12:59:31.446596	1
86	UPDATE	products	6	{"new": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 280, "reserved_quantity": 71}, "old": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 196, "reserved_quantity": 16}}	2025-02-07 12:59:31.446596	1
87	INSERT	product_batches	23	{"new": {"batch_id": 23, "quantity": 17, "product_id": 7, "arrival_date": "2024-12-31", "selling_price": 49215.60, "purchase_price": 39645.35}, "old": null}	2025-02-07 12:59:31.446596	1
88	UPDATE	products	7	{"new": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 139, "reserved_quantity": 22}, "old": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 122, "reserved_quantity": 22}}	2025-02-07 12:59:31.446596	1
89	UPDATE	products	7	{"new": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 156, "reserved_quantity": 35}, "old": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 139, "reserved_quantity": 22}}	2025-02-07 12:59:31.446596	1
90	INSERT	product_batches	24	{"new": {"batch_id": 24, "quantity": 66, "product_id": 8, "arrival_date": "2024-02-12", "selling_price": 25309.16, "purchase_price": 22953.29}, "old": null}	2025-02-07 12:59:31.446596	1
91	UPDATE	products	8	{"new": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 264, "reserved_quantity": 31}, "old": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 198, "reserved_quantity": 31}}	2025-02-07 12:59:31.446596	1
92	UPDATE	products	8	{"new": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 330, "reserved_quantity": 81}, "old": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 264, "reserved_quantity": 31}}	2025-02-07 12:59:31.446596	1
93	INSERT	product_batches	25	{"new": {"batch_id": 25, "quantity": 82, "product_id": 9, "arrival_date": "2024-05-30", "selling_price": 34290.03, "purchase_price": 27235.67}, "old": null}	2025-02-07 12:59:31.446596	1
94	UPDATE	products	9	{"new": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 146, "reserved_quantity": 12}, "old": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 64, "reserved_quantity": 12}}	2025-02-07 12:59:31.446596	1
95	UPDATE	products	9	{"new": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 228, "reserved_quantity": 41}, "old": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 146, "reserved_quantity": 12}}	2025-02-07 12:59:31.446596	1
96	INSERT	product_batches	26	{"new": {"batch_id": 26, "quantity": 83, "product_id": 10, "arrival_date": "2024-07-07", "selling_price": 48892.30, "purchase_price": 38122.41}, "old": null}	2025-02-07 12:59:31.446596	1
97	UPDATE	products	10	{"new": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 193, "reserved_quantity": 12}, "old": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 110, "reserved_quantity": 12}}	2025-02-07 12:59:31.446596	1
98	UPDATE	products	10	{"new": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 276, "reserved_quantity": 42}, "old": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 193, "reserved_quantity": 12}}	2025-02-07 12:59:31.446596	1
99	INSERT	product_batches	27	{"new": {"batch_id": 27, "quantity": 74, "product_id": 11, "arrival_date": "2024-06-11", "selling_price": 46439.81, "purchase_price": 38175.49}, "old": null}	2025-02-07 12:59:31.446596	1
100	UPDATE	products	11	{"new": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 158, "reserved_quantity": 12}, "old": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 84, "reserved_quantity": 12}}	2025-02-07 12:59:31.446596	1
101	UPDATE	products	11	{"new": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 232, "reserved_quantity": 59}, "old": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 158, "reserved_quantity": 12}}	2025-02-07 12:59:31.446596	1
102	INSERT	product_batches	28	{"new": {"batch_id": 28, "quantity": 97, "product_id": 12, "arrival_date": "2024-06-03", "selling_price": 35243.42, "purchase_price": 31873.31}, "old": null}	2025-02-07 12:59:31.446596	1
103	UPDATE	products	12	{"new": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 135, "reserved_quantity": 4}, "old": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 38, "reserved_quantity": 4}}	2025-02-07 12:59:31.446596	1
104	UPDATE	products	12	{"new": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 232, "reserved_quantity": 41}, "old": {"name": "Ноутбук 4", "product_id": 12, "category_id": 3, "description": "", "total_quantity": 135, "reserved_quantity": 4}}	2025-02-07 12:59:31.446596	1
105	INSERT	product_batches	29	{"new": {"batch_id": 29, "quantity": 69, "product_id": 13, "arrival_date": "2024-10-09", "selling_price": 28756.93, "purchase_price": 24789.07}, "old": null}	2025-02-07 12:59:31.446596	1
106	UPDATE	products	13	{"new": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 163, "reserved_quantity": 16}, "old": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 94, "reserved_quantity": 16}}	2025-02-07 12:59:31.446596	1
107	UPDATE	products	13	{"new": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 232, "reserved_quantity": 42}, "old": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 163, "reserved_quantity": 16}}	2025-02-07 12:59:31.446596	1
108	INSERT	product_batches	30	{"new": {"batch_id": 30, "quantity": 55, "product_id": 14, "arrival_date": "2024-02-25", "selling_price": 27478.47, "purchase_price": 24581.97}, "old": null}	2025-02-07 12:59:31.446596	1
109	UPDATE	products	14	{"new": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 119, "reserved_quantity": 9}, "old": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 64, "reserved_quantity": 9}}	2025-02-07 12:59:31.446596	1
110	UPDATE	products	14	{"new": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 174, "reserved_quantity": 25}, "old": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 119, "reserved_quantity": 9}}	2025-02-07 12:59:31.446596	1
111	INSERT	product_batches	31	{"new": {"batch_id": 31, "quantity": 75, "product_id": 15, "arrival_date": "2024-12-06", "selling_price": 47757.46, "purchase_price": 42576.91}, "old": null}	2025-02-07 12:59:31.446596	1
112	UPDATE	products	15	{"new": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 191, "reserved_quantity": 13}, "old": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 116, "reserved_quantity": 13}}	2025-02-07 12:59:31.446596	1
113	UPDATE	products	15	{"new": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 266, "reserved_quantity": 68}, "old": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 191, "reserved_quantity": 13}}	2025-02-07 12:59:31.446596	1
114	INSERT	product_batches	32	{"new": {"batch_id": 32, "quantity": 45, "product_id": 16, "arrival_date": "2024-05-06", "selling_price": 14877.87, "purchase_price": 12097.18}, "old": null}	2025-02-07 12:59:31.446596	1
115	UPDATE	products	16	{"new": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 95, "reserved_quantity": 10}, "old": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 50, "reserved_quantity": 10}}	2025-02-07 12:59:31.446596	1
116	UPDATE	products	16	{"new": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 140, "reserved_quantity": 34}, "old": {"name": "Наушники 4", "product_id": 16, "category_id": 4, "description": "", "total_quantity": 95, "reserved_quantity": 10}}	2025-02-07 12:59:31.446596	1
117	INSERT	customers	1	{"new": {"name": "Иван Иванов", "email": "ivan@example.com", "customer_id": 1}, "old": null}	2025-02-07 12:59:31.546644	1
118	INSERT	customers	2	{"new": {"name": "Петр Петров", "email": "petr@example.com", "customer_id": 2}, "old": null}	2025-02-07 12:59:31.546644	1
119	INSERT	customers	3	{"new": {"name": "Мария Марьевна", "email": "maria@example.com", "customer_id": 3}, "old": null}	2025-02-07 12:59:31.546644	1
120	INSERT	customers	4	{"new": {"name": "Владимир Мезерный", "email": "vovamez.work@example.com", "customer_id": 4}, "old": null}	2025-02-07 12:59:31.546644	1
121	INSERT	orders	1	{"new": {"status": "оформлен", "order_id": 1, "order_date": "2024-10-25", "customer_id": 1, "shipping_address": "ул. Пример 1"}, "old": null}	2025-02-07 12:59:31.560542	1
122	INSERT	orders	2	{"new": {"status": "оплачен", "order_id": 2, "order_date": "2024-11-15", "customer_id": 2, "shipping_address": "ул. Пример 2"}, "old": null}	2025-02-07 12:59:31.560542	1
123	INSERT	orders	3	{"new": {"status": "доставлен", "order_id": 3, "order_date": "2024-11-10", "customer_id": 3, "shipping_address": "ул. Пример 3"}, "old": null}	2025-02-07 12:59:31.560542	1
124	INSERT	orders	4	{"new": {"status": "оформлен", "order_id": 4, "order_date": "2024-12-05", "customer_id": 4, "shipping_address": "ул. Пример 4"}, "old": null}	2025-02-07 12:59:31.560542	1
125	INSERT	orders	5	{"new": {"status": "оплачен", "order_id": 5, "order_date": "2024-12-20", "customer_id": 1, "shipping_address": "ул. Пример 1"}, "old": null}	2025-02-07 12:59:31.560542	1
126	INSERT	orders	6	{"new": {"status": "доставлен", "order_id": 6, "order_date": "2024-01-01", "customer_id": 2, "shipping_address": "ул. Пример 2"}, "old": null}	2025-02-07 12:59:31.560542	1
127	INSERT	orders	7	{"new": {"status": "отменён", "order_id": 7, "order_date": "2025-01-10", "customer_id": 3, "shipping_address": "ул. Пример 3"}, "old": null}	2025-02-07 12:59:31.560542	1
128	UPDATE	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 204, "reserved_quantity": 34}, "old": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 204, "reserved_quantity": 32}}	2025-02-07 12:59:31.576574	1
129	UPDATE	products	5	{"new": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 80, "reserved_quantity": 24}, "old": {"name": "Планшет 1", "product_id": 5, "category_id": 2, "description": "", "total_quantity": 80, "reserved_quantity": 23}}	2025-02-07 12:59:31.576574	1
130	UPDATE	products	9	{"new": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 228, "reserved_quantity": 42}, "old": {"name": "Ноутбук 1", "product_id": 9, "category_id": 3, "description": "", "total_quantity": 228, "reserved_quantity": 41}}	2025-02-07 12:59:31.576574	1
131	UPDATE	products	13	{"new": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 232, "reserved_quantity": 44}, "old": {"name": "Наушники 1", "product_id": 13, "category_id": 4, "description": "", "total_quantity": 232, "reserved_quantity": 42}}	2025-02-07 12:59:31.576574	1
132	UPDATE	products	3	{"new": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 304, "reserved_quantity": 79}, "old": {"name": "Смартфон 3", "product_id": 3, "category_id": 1, "description": "", "total_quantity": 304, "reserved_quantity": 78}}	2025-02-07 12:59:31.576574	1
133	UPDATE	products	7	{"new": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 156, "reserved_quantity": 36}, "old": {"name": "Планшет 3", "product_id": 7, "category_id": 2, "description": "", "total_quantity": 156, "reserved_quantity": 35}}	2025-02-07 12:59:31.576574	1
134	UPDATE	products	11	{"new": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 232, "reserved_quantity": 60}, "old": {"name": "Ноутбук 3", "product_id": 11, "category_id": 3, "description": "", "total_quantity": 232, "reserved_quantity": 59}}	2025-02-07 12:59:31.576574	1
135	UPDATE	products	15	{"new": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 266, "reserved_quantity": 71}, "old": {"name": "Наушники 3", "product_id": 15, "category_id": 4, "description": "", "total_quantity": 266, "reserved_quantity": 68}}	2025-02-07 12:59:31.576574	1
136	UPDATE	products	2	{"new": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 170, "reserved_quantity": 41}, "old": {"name": "Смартфон 2", "product_id": 2, "category_id": 1, "description": "", "total_quantity": 170, "reserved_quantity": 40}}	2025-02-07 12:59:31.576574	1
137	UPDATE	products	6	{"new": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 280, "reserved_quantity": 73}, "old": {"name": "Планшет 2", "product_id": 6, "category_id": 2, "description": "", "total_quantity": 280, "reserved_quantity": 71}}	2025-02-07 12:59:31.576574	1
138	UPDATE	products	10	{"new": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 276, "reserved_quantity": 43}, "old": {"name": "Ноутбук 2", "product_id": 10, "category_id": 3, "description": "", "total_quantity": 276, "reserved_quantity": 42}}	2025-02-07 12:59:31.576574	1
139	UPDATE	products	14	{"new": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 174, "reserved_quantity": 26}, "old": {"name": "Наушники 2", "product_id": 14, "category_id": 4, "description": "", "total_quantity": 174, "reserved_quantity": 25}}	2025-02-07 12:59:31.576574	1
140	UPDATE	products	4	{"new": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 230, "reserved_quantity": 61}, "old": {"name": "Смартфон 4", "product_id": 4, "category_id": 1, "description": "", "total_quantity": 230, "reserved_quantity": 60}}	2025-02-07 12:59:31.576574	1
141	UPDATE	products	8	{"new": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 330, "reserved_quantity": 82}, "old": {"name": "Планшет 4", "product_id": 8, "category_id": 2, "description": "", "total_quantity": 330, "reserved_quantity": 81}}	2025-02-07 12:59:31.576574	1
142	INSERT	order_items	1	{"new": {"price": 25000.00, "order_id": 1, "quantity": 2, "product_id": 1, "order_item_id": 1}, "old": null}	2025-02-07 12:59:31.576574	1
143	INSERT	order_items	2	{"new": {"price": 40000.00, "order_id": 1, "quantity": 1, "product_id": 5, "order_item_id": 2}, "old": null}	2025-02-07 12:59:31.576574	1
144	INSERT	order_items	3	{"new": {"price": 80000.00, "order_id": 2, "quantity": 1, "product_id": 9, "order_item_id": 3}, "old": null}	2025-02-07 12:59:31.576574	1
145	INSERT	order_items	4	{"new": {"price": 5000.00, "order_id": 2, "quantity": 2, "product_id": 13, "order_item_id": 4}, "old": null}	2025-02-07 12:59:31.576574	1
146	INSERT	order_items	5	{"new": {"price": 30000.00, "order_id": 3, "quantity": 1, "product_id": 3, "order_item_id": 5}, "old": null}	2025-02-07 12:59:31.576574	1
147	INSERT	order_items	6	{"new": {"price": 45000.00, "order_id": 3, "quantity": 1, "product_id": 7, "order_item_id": 6}, "old": null}	2025-02-07 12:59:31.576574	1
148	INSERT	order_items	7	{"new": {"price": 90000.00, "order_id": 4, "quantity": 1, "product_id": 11, "order_item_id": 7}, "old": null}	2025-02-07 12:59:31.576574	1
149	INSERT	order_items	8	{"new": {"price": 7000.00, "order_id": 4, "quantity": 3, "product_id": 15, "order_item_id": 8}, "old": null}	2025-02-07 12:59:31.576574	1
150	INSERT	order_items	9	{"new": {"price": 27000.00, "order_id": 5, "quantity": 1, "product_id": 2, "order_item_id": 9}, "old": null}	2025-02-07 12:59:31.576574	1
151	INSERT	order_items	10	{"new": {"price": 42000.00, "order_id": 5, "quantity": 2, "product_id": 6, "order_item_id": 10}, "old": null}	2025-02-07 12:59:31.576574	1
152	INSERT	order_items	11	{"new": {"price": 85000.00, "order_id": 6, "quantity": 1, "product_id": 10, "order_item_id": 11}, "old": null}	2025-02-07 12:59:31.576574	1
153	INSERT	order_items	12	{"new": {"price": 6000.00, "order_id": 6, "quantity": 1, "product_id": 14, "order_item_id": 12}, "old": null}	2025-02-07 12:59:31.576574	1
154	INSERT	order_items	13	{"new": {"price": 32000.00, "order_id": 7, "quantity": 1, "product_id": 4, "order_item_id": 13}, "old": null}	2025-02-07 12:59:31.576574	1
155	INSERT	order_items	14	{"new": {"price": 47000.00, "order_id": 7, "quantity": 1, "product_id": 8, "order_item_id": 14}, "old": null}	2025-02-07 12:59:31.576574	1
156	INSERT	categories	5	{"new": {"name": "Новая категория", "category_id": 5}, "old": null}	2025-02-07 13:00:33.342409	1
157	UPDATE	categories	5	{"new": {"name": "Обновлённая категория 2", "category_id": 5}, "old": {"name": "Новая категория", "category_id": 5}}	2025-02-07 13:00:34.370045	1
158	DELETE	categories	5	{"new": null, "old": {"name": "Обновлённая категория 2", "category_id": 5}}	2025-02-07 13:00:35.163851	1
159	INSERT	products	17	{"new": {"name": "Новый товар", "product_id": 17, "category_id": 1, "description": "Описание нового товара", "total_quantity": 100, "reserved_quantity": 10}, "old": null}	2025-02-07 13:00:36.418872	1
160	UPDATE	products	17	{"new": {"name": "Обновлённый товар", "product_id": 17, "category_id": 2, "description": "Новое описание", "total_quantity": 150, "reserved_quantity": 20}, "old": {"name": "Новый товар", "product_id": 17, "category_id": 1, "description": "Описание нового товара", "total_quantity": 100, "reserved_quantity": 10}}	2025-02-07 13:00:37.497095	1
161	DELETE	products	17	{"new": null, "old": {"name": "Обновлённый товар", "product_id": 17, "category_id": 2, "description": "Новое описание", "total_quantity": 150, "reserved_quantity": 20}}	2025-02-07 13:00:38.203091	1
162	INSERT	product_batches	33	{"new": {"batch_id": 33, "quantity": 50, "product_id": 1, "arrival_date": "2023-10-01", "selling_price": 15000.00, "purchase_price": 10000.00}, "old": null}	2025-02-07 13:00:39.27015	1
163	UPDATE	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 254, "reserved_quantity": 34}, "old": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 204, "reserved_quantity": 34}}	2025-02-07 13:00:39.27015	1
164	UPDATE	product_batches	33	{"new": {"batch_id": 33, "quantity": 60, "product_id": 2, "arrival_date": "2023-10-05", "selling_price": 18000.00, "purchase_price": 12000.00}, "old": {"batch_id": 33, "quantity": 50, "product_id": 1, "arrival_date": "2023-10-01", "selling_price": 15000.00, "purchase_price": 10000.00}}	2025-02-07 13:00:45.555722	1
165	DELETE	product_batches	33	{"new": null, "old": {"batch_id": 33, "quantity": 60, "product_id": 2, "arrival_date": "2023-10-05", "selling_price": 18000.00, "purchase_price": 12000.00}}	2025-02-07 13:00:50.668771	1
166	INSERT	customers	5	{"new": {"name": "Новый клиент", "email": "new-customer@example.com", "customer_id": 5}, "old": null}	2025-02-07 13:01:24.906682	1
167	UPDATE	customers	5	{"new": {"name": "Обновлённый клиент", "email": "updated-customer@example.com", "customer_id": 5}, "old": {"name": "Новый клиент", "email": "new-customer@example.com", "customer_id": 5}}	2025-02-07 13:01:28.923417	1
168	DELETE	customers	5	{"new": null, "old": {"name": "Обновлённый клиент", "email": "updated-customer@example.com", "customer_id": 5}}	2025-02-07 13:01:32.877921	1
169	INSERT	orders	8	{"new": {"status": "оформлен", "order_id": 8, "order_date": "2025-02-07", "customer_id": 1, "shipping_address": "ул. Ленина, д. 10"}, "old": null}	2025-02-07 13:01:35.1651	1
170	UPDATE	orders	8	{"new": {"status": "отменён", "order_id": 8, "order_date": "2025-02-07", "customer_id": 2, "shipping_address": "ул. Ленина, д. 15"}, "old": {"status": "оформлен", "order_id": 8, "order_date": "2025-02-07", "customer_id": 1, "shipping_address": "ул. Ленина, д. 10"}}	2025-02-07 13:01:44.109303	1
171	DELETE	orders	8	{"new": null, "old": {"status": "отменён", "order_id": 8, "order_date": "2025-02-07", "customer_id": 2, "shipping_address": "ул. Ленина, д. 15"}}	2025-02-07 13:01:45.540068	1
172	UPDATE	products	1	{"new": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 254, "reserved_quantity": 36}, "old": {"name": "Смартфон 1", "product_id": 1, "category_id": 1, "description": "", "total_quantity": 254, "reserved_quantity": 34}}	2025-02-07 13:01:47.105104	1
173	INSERT	order_items	15	{"new": {"price": 25000.00, "order_id": 1, "quantity": 2, "product_id": 1, "order_item_id": 15}, "old": null}	2025-02-07 13:01:47.105104	1
174	UPDATE	order_items	15	{"new": {"price": 30000.00, "order_id": 2, "quantity": 3, "product_id": 2, "order_item_id": 15}, "old": {"price": 25000.00, "order_id": 1, "quantity": 2, "product_id": 1, "order_item_id": 15}}	2025-02-07 13:01:53.346236	1
175	DELETE	order_items	15	{"new": null, "old": {"price": 30000.00, "order_id": 2, "quantity": 3, "product_id": 2, "order_item_id": 15}}	2025-02-07 13:01:54.844401	1
\.


--
-- TOC entry 5069 (class 0 OID 63743)
-- Dependencies: 255
-- Data for Name: error_logs; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.error_logs (error_id, error_message, error_details, error_time, user_id) FROM stdin;
\.


--
-- TOC entry 4770 (class 0 OID 16389)
-- Dependencies: 225
-- Data for Name: pga_jobagent; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobagent (jagpid, jaglogintime, jagstation) FROM stdin;
8016	2025-02-07 12:22:29.94078+03	Aboba
\.


--
-- TOC entry 4771 (class 0 OID 16398)
-- Dependencies: 227
-- Data for Name: pga_jobclass; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobclass (jclid, jclname) FROM stdin;
\.


--
-- TOC entry 4772 (class 0 OID 16408)
-- Dependencies: 229
-- Data for Name: pga_job; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobhostagent, jobenabled, jobcreated, jobchanged, jobagentid, jobnextrun, joblastrun) FROM stdin;
\.


--
-- TOC entry 4774 (class 0 OID 16456)
-- Dependencies: 233
-- Data for Name: pga_schedule; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths) FROM stdin;
\.


--
-- TOC entry 4775 (class 0 OID 16484)
-- Dependencies: 235
-- Data for Name: pga_exception; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_exception (jexid, jexscid, jexdate, jextime) FROM stdin;
\.


--
-- TOC entry 4776 (class 0 OID 16498)
-- Dependencies: 237
-- Data for Name: pga_joblog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_joblog (jlgid, jlgjobid, jlgstatus, jlgstart, jlgduration) FROM stdin;
\.


--
-- TOC entry 4773 (class 0 OID 16432)
-- Dependencies: 231
-- Data for Name: pga_jobstep; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstcode, jstconnstr, jstdbname, jstonerror, jscnextrun) FROM stdin;
\.


--
-- TOC entry 4777 (class 0 OID 16514)
-- Dependencies: 239
-- Data for Name: pga_jobsteplog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobsteplog (jslid, jsljlgid, jsljstid, jslstatus, jslresult, jslstart, jslduration, jsloutput) FROM stdin;
\.


--
-- TOC entry 5061 (class 0 OID 63686)
-- Dependencies: 247
-- Data for Name: customers; Type: TABLE DATA; Schema: sales; Owner: postgres
--

COPY sales.customers (customer_id, name, email) FROM stdin;
1	Иван Иванов	ivan@example.com
2	Петр Петров	petr@example.com
3	Мария Марьевна	maria@example.com
4	Владимир Мезерный	vovamez.work@example.com
\.


--
-- TOC entry 5065 (class 0 OID 63713)
-- Dependencies: 251
-- Data for Name: order_items; Type: TABLE DATA; Schema: sales; Owner: postgres
--

COPY sales.order_items (order_item_id, order_id, product_id, quantity, price) FROM stdin;
1	1	1	2	25000.00
2	1	5	1	40000.00
3	2	9	1	80000.00
4	2	13	2	5000.00
5	3	3	1	30000.00
6	3	7	1	45000.00
7	4	11	1	90000.00
8	4	15	3	7000.00
9	5	2	1	27000.00
10	5	6	2	42000.00
11	6	10	1	85000.00
12	6	14	1	6000.00
13	7	4	1	32000.00
14	7	8	1	47000.00
\.


--
-- TOC entry 5063 (class 0 OID 63697)
-- Dependencies: 249
-- Data for Name: orders; Type: TABLE DATA; Schema: sales; Owner: postgres
--

COPY sales.orders (order_id, customer_id, order_date, status, shipping_address) FROM stdin;
1	1	2024-10-25	оформлен	ул. Пример 1
2	2	2024-11-15	оплачен	ул. Пример 2
3	3	2024-11-10	доставлен	ул. Пример 3
4	4	2024-12-05	оформлен	ул. Пример 4
5	1	2024-12-20	оплачен	ул. Пример 1
6	2	2024-01-01	доставлен	ул. Пример 2
7	3	2025-01-10	отменён	ул. Пример 3
\.


--
-- TOC entry 5055 (class 0 OID 63640)
-- Dependencies: 241
-- Data for Name: categories; Type: TABLE DATA; Schema: storage; Owner: postgres
--

COPY storage.categories (category_id, name) FROM stdin;
1	Смартфоны
2	Планшеты
3	Ноутбуки
4	Наушники
\.


--
-- TOC entry 5059 (class 0 OID 63669)
-- Dependencies: 245
-- Data for Name: product_batches; Type: TABLE DATA; Schema: storage; Owner: postgres
--

COPY storage.product_batches (batch_id, product_id, purchase_price, selling_price, quantity, arrival_date) FROM stdin;
1	1	41861.91	49379.49	41	2024-02-11
2	2	43870.46	50738.55	42	2025-01-27
3	3	22659.61	27277.69	70	2024-12-09
4	4	14454.17	18557.47	46	2024-04-06
5	5	34070.90	43791.27	26	2024-09-07
6	6	20337.69	24953.77	56	2024-03-28
7	7	39303.79	50626.94	61	2024-04-20
8	8	15191.73	17944.48	99	2024-06-04
9	9	29352.61	37563.41	32	2024-05-24
10	10	25085.06	30898.82	55	2024-08-21
11	11	49474.47	58982.42	42	2024-11-06
12	12	41729.64	53011.97	19	2024-02-24
13	13	48996.98	55764.91	47	2024-10-28
14	14	14222.66	16000.83	32	2025-01-20
15	15	22330.51	24734.00	58	2024-08-09
16	16	27708.61	35239.39	25	2024-08-02
17	1	35523.34	40277.53	61	2024-06-17
18	2	23503.76	28862.60	43	2024-10-30
19	3	47656.24	60337.14	82	2024-10-12
20	4	39887.62	51055.50	69	2024-09-11
21	5	37065.92	46938.29	14	2024-06-10
22	6	34397.23	38523.72	84	2024-04-07
23	7	39645.35	49215.60	17	2024-12-31
24	8	22953.29	25309.16	66	2024-02-12
25	9	27235.67	34290.03	82	2024-05-30
26	10	38122.41	48892.30	83	2024-07-07
27	11	38175.49	46439.81	74	2024-06-11
28	12	31873.31	35243.42	97	2024-06-03
29	13	24789.07	28756.93	69	2024-10-09
30	14	24581.97	27478.47	55	2024-02-25
31	15	42576.91	47757.46	75	2024-12-06
32	16	12097.18	14877.87	45	2024-05-06
\.


--
-- TOC entry 5057 (class 0 OID 63649)
-- Dependencies: 243
-- Data for Name: products; Type: TABLE DATA; Schema: storage; Owner: postgres
--

COPY storage.products (product_id, name, category_id, description, total_quantity, reserved_quantity) FROM stdin;
1	Смартфон 1	1		254	36
12	Ноутбук 4	3		232	41
16	Наушники 4	4		140	34
5	Планшет 1	2		80	24
9	Ноутбук 1	3		228	42
13	Наушники 1	4		232	44
3	Смартфон 3	1		304	79
7	Планшет 3	2		156	36
11	Ноутбук 3	3		232	60
15	Наушники 3	4		266	71
2	Смартфон 2	1		170	41
6	Планшет 2	2		280	73
10	Ноутбук 2	3		276	43
14	Наушники 2	4		174	26
4	Смартфон 4	1		230	61
8	Планшет 4	2		330	82
\.


--
-- TOC entry 5085 (class 0 OID 0)
-- Dependencies: 252
-- Name: action_logs_action_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.action_logs_action_id_seq', 175, true);


--
-- TOC entry 5086 (class 0 OID 0)
-- Dependencies: 254
-- Name: error_logs_error_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.error_logs_error_id_seq', 1, false);


--
-- TOC entry 5087 (class 0 OID 0)
-- Dependencies: 246
-- Name: customers_customer_id_seq; Type: SEQUENCE SET; Schema: sales; Owner: postgres
--

SELECT pg_catalog.setval('sales.customers_customer_id_seq', 5, true);


--
-- TOC entry 5088 (class 0 OID 0)
-- Dependencies: 250
-- Name: order_items_order_item_id_seq; Type: SEQUENCE SET; Schema: sales; Owner: postgres
--

SELECT pg_catalog.setval('sales.order_items_order_item_id_seq', 15, true);


--
-- TOC entry 5089 (class 0 OID 0)
-- Dependencies: 248
-- Name: orders_order_id_seq; Type: SEQUENCE SET; Schema: sales; Owner: postgres
--

SELECT pg_catalog.setval('sales.orders_order_id_seq', 8, true);


--
-- TOC entry 5090 (class 0 OID 0)
-- Dependencies: 240
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: storage; Owner: postgres
--

SELECT pg_catalog.setval('storage.categories_category_id_seq', 5, true);


--
-- TOC entry 5091 (class 0 OID 0)
-- Dependencies: 244
-- Name: product_batches_batch_id_seq; Type: SEQUENCE SET; Schema: storage; Owner: postgres
--

SELECT pg_catalog.setval('storage.product_batches_batch_id_seq', 33, true);


--
-- TOC entry 5092 (class 0 OID 0)
-- Dependencies: 242
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: storage; Owner: postgres
--

SELECT pg_catalog.setval('storage.products_product_id_seq', 17, true);


--
-- TOC entry 4885 (class 2606 OID 63737)
-- Name: action_logs action_logs_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.action_logs
    ADD CONSTRAINT action_logs_pkey PRIMARY KEY (action_id);


--
-- TOC entry 4891 (class 2606 OID 63752)
-- Name: error_logs error_logs_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.error_logs
    ADD CONSTRAINT error_logs_pkey PRIMARY KEY (error_id);


--
-- TOC entry 4877 (class 2606 OID 63695)
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- TOC entry 4879 (class 2606 OID 63693)
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- TOC entry 4883 (class 2606 OID 63720)
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (order_item_id);


--
-- TOC entry 4881 (class 2606 OID 63706)
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- TOC entry 4867 (class 2606 OID 63647)
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- TOC entry 4869 (class 2606 OID 63645)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4875 (class 2606 OID 63678)
-- Name: product_batches product_batches_pkey; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.product_batches
    ADD CONSTRAINT product_batches_pkey PRIMARY KEY (batch_id);


--
-- TOC entry 4871 (class 2606 OID 63662)
-- Name: products products_name_key; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.products
    ADD CONSTRAINT products_name_key UNIQUE (name);


--
-- TOC entry 4873 (class 2606 OID 63660)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- TOC entry 4886 (class 1259 OID 63738)
-- Name: idx_action_logs_action_time; Type: INDEX; Schema: admin; Owner: postgres
--

CREATE INDEX idx_action_logs_action_time ON admin.action_logs USING btree (action_time);


--
-- TOC entry 4887 (class 1259 OID 63740)
-- Name: idx_action_logs_record_id; Type: INDEX; Schema: admin; Owner: postgres
--

CREATE INDEX idx_action_logs_record_id ON admin.action_logs USING btree (record_id);


--
-- TOC entry 4888 (class 1259 OID 63739)
-- Name: idx_action_logs_table_name; Type: INDEX; Schema: admin; Owner: postgres
--

CREATE INDEX idx_action_logs_table_name ON admin.action_logs USING btree (table_name);


--
-- TOC entry 4889 (class 1259 OID 63741)
-- Name: idx_action_logs_user_id; Type: INDEX; Schema: admin; Owner: postgres
--

CREATE INDEX idx_action_logs_user_id ON admin.action_logs USING btree (user_id);


--
-- TOC entry 4892 (class 1259 OID 63753)
-- Name: idx_error_logs_error_time; Type: INDEX; Schema: admin; Owner: postgres
--

CREATE INDEX idx_error_logs_error_time ON admin.error_logs USING btree (error_time);


--
-- TOC entry 4893 (class 1259 OID 63754)
-- Name: idx_error_logs_user_id; Type: INDEX; Schema: admin; Owner: postgres
--

CREATE INDEX idx_error_logs_user_id ON admin.error_logs USING btree (user_id);


--
-- TOC entry 5051 (class 2618 OID 63758)
-- Name: storage_data_view _RETURN; Type: RULE; Schema: storage; Owner: postgres
--

CREATE OR REPLACE VIEW storage.storage_data_view AS
 SELECT p.product_id AS "Идентификатор товара",
    p.name AS "Название товара",
    c.name AS "Категория",
    p.total_quantity AS "Общее количество",
    p.reserved_quantity AS "Зарезервировано",
    (p.total_quantity - p.reserved_quantity) AS "Доступно"
   FROM (storage.categories c
     JOIN storage.products p ON ((c.category_id = p.category_id)))
  GROUP BY p.product_id, p.name, c.name
  ORDER BY p.product_id, c.name;


--
-- TOC entry 4904 (class 2620 OID 63813)
-- Name: order_items trg_check_product_availability; Type: TRIGGER; Schema: sales; Owner: postgres
--

CREATE TRIGGER trg_check_product_availability BEFORE INSERT ON sales.order_items FOR EACH ROW EXECUTE FUNCTION sales.check_product_availability();


--
-- TOC entry 4902 (class 2620 OID 63807)
-- Name: customers trg_customers_changes; Type: TRIGGER; Schema: sales; Owner: postgres
--

CREATE TRIGGER trg_customers_changes AFTER INSERT OR DELETE OR UPDATE ON sales.customers FOR EACH ROW EXECUTE FUNCTION admin.log_all_changes_and_errors();


--
-- TOC entry 4905 (class 2620 OID 63809)
-- Name: order_items trg_order_items_changes; Type: TRIGGER; Schema: sales; Owner: postgres
--

CREATE TRIGGER trg_order_items_changes AFTER INSERT OR DELETE OR UPDATE ON sales.order_items FOR EACH ROW EXECUTE FUNCTION admin.log_all_changes_and_errors();


--
-- TOC entry 4903 (class 2620 OID 63808)
-- Name: orders trg_orders_changes; Type: TRIGGER; Schema: sales; Owner: postgres
--

CREATE TRIGGER trg_orders_changes AFTER INSERT OR DELETE OR UPDATE ON sales.orders FOR EACH ROW EXECUTE FUNCTION admin.log_all_changes_and_errors();


--
-- TOC entry 4898 (class 2620 OID 63804)
-- Name: categories trg_categories_changes; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER trg_categories_changes AFTER INSERT OR DELETE OR UPDATE ON storage.categories FOR EACH ROW EXECUTE FUNCTION admin.log_all_changes_and_errors();


--
-- TOC entry 4900 (class 2620 OID 63806)
-- Name: product_batches trg_product_batches_changes; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER trg_product_batches_changes AFTER INSERT OR DELETE OR UPDATE ON storage.product_batches FOR EACH ROW EXECUTE FUNCTION admin.log_all_changes_and_errors();


--
-- TOC entry 4899 (class 2620 OID 63805)
-- Name: products trg_products_changes; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER trg_products_changes AFTER INSERT OR DELETE OR UPDATE ON storage.products FOR EACH ROW EXECUTE FUNCTION admin.log_all_changes_and_errors();


--
-- TOC entry 4901 (class 2620 OID 63811)
-- Name: product_batches trg_update_total_quantity; Type: TRIGGER; Schema: storage; Owner: postgres
--

CREATE TRIGGER trg_update_total_quantity AFTER INSERT ON storage.product_batches FOR EACH ROW EXECUTE FUNCTION storage.update_total_quantity();


--
-- TOC entry 4897 (class 2606 OID 63721)
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES sales.orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4896 (class 2606 OID 63707)
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4895 (class 2606 OID 63679)
-- Name: product_batches product_batches_product_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.product_batches
    ADD CONSTRAINT product_batches_product_id_fkey FOREIGN KEY (product_id) REFERENCES storage.products(product_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4894 (class 2606 OID 63663)
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: postgres
--

ALTER TABLE ONLY storage.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES storage.categories(category_id) ON UPDATE CASCADE ON DELETE SET NULL;


-- Completed on 2025-02-07 14:07:12

--
-- PostgreSQL database dump complete
--

--
-- Database "sells-storage" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-02-07 14:07:12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4853 (class 1262 OID 16551)
-- Name: sells-storage; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "sells-storage" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';


ALTER DATABASE "sells-storage" OWNER TO postgres;

\connect -reuse-previous=on "dbname='sells-storage'"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 16553)
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    category_id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16552)
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_category_id_seq OWNER TO postgres;

--
-- TOC entry 4854 (class 0 OID 0)
-- Dependencies: 217
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;


--
-- TOC entry 222 (class 1259 OID 16577)
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16576)
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_customer_id_seq OWNER TO postgres;

--
-- TOC entry 4855 (class 0 OID 0)
-- Dependencies: 221
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_customer_id_seq OWNED BY public.customers.customer_id;


--
-- TOC entry 226 (class 1259 OID 16603)
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    order_item_id integer NOT NULL,
    order_id integer,
    product_id integer,
    quantity integer NOT NULL,
    price numeric(10,2) NOT NULL,
    CONSTRAINT order_items_price_check CHECK ((price > (0)::numeric)),
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16602)
-- Name: order_items_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_order_item_id_seq OWNER TO postgres;

--
-- TOC entry 4856 (class 0 OID 0)
-- Dependencies: 225
-- Name: order_items_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_order_item_id_seq OWNED BY public.order_items.order_item_id;


--
-- TOC entry 224 (class 1259 OID 16588)
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    order_id integer NOT NULL,
    customer_id integer,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    CONSTRAINT orders_total_amount_check CHECK ((total_amount > (0)::numeric))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16587)
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_order_id_seq OWNER TO postgres;

--
-- TOC entry 4857 (class 0 OID 0)
-- Dependencies: 223
-- Name: orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_order_id_seq OWNED BY public.orders.order_id;


--
-- TOC entry 220 (class 1259 OID 16562)
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    product_id integer NOT NULL,
    name character varying(255) NOT NULL,
    category_id integer,
    price numeric(10,2) NOT NULL,
    stock_quantity integer NOT NULL,
    CONSTRAINT products_price_check CHECK ((price > (0)::numeric)),
    CONSTRAINT products_stock_quantity_check CHECK ((stock_quantity >= 0))
);


ALTER TABLE public.products OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16561)
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_product_id_seq OWNER TO postgres;

--
-- TOC entry 4858 (class 0 OID 0)
-- Dependencies: 219
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- TOC entry 4661 (class 2604 OID 16556)
-- Name: categories category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);


--
-- TOC entry 4663 (class 2604 OID 16580)
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customers_customer_id_seq'::regclass);


--
-- TOC entry 4666 (class 2604 OID 16606)
-- Name: order_items order_item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN order_item_id SET DEFAULT nextval('public.order_items_order_item_id_seq'::regclass);


--
-- TOC entry 4664 (class 2604 OID 16591)
-- Name: orders order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN order_id SET DEFAULT nextval('public.orders_order_id_seq'::regclass);


--
-- TOC entry 4662 (class 2604 OID 16565)
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- TOC entry 4839 (class 0 OID 16553)
-- Dependencies: 218
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (category_id, name) FROM stdin;
1	Электроника
2	Одежда
3	Книги
4	Дом и сад
5	Спорт и отдых
\.


--
-- TOC entry 4843 (class 0 OID 16577)
-- Dependencies: 222
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (customer_id, name, email) FROM stdin;
\.


--
-- TOC entry 4847 (class 0 OID 16603)
-- Dependencies: 226
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (order_item_id, order_id, product_id, quantity, price) FROM stdin;
\.


--
-- TOC entry 4845 (class 0 OID 16588)
-- Dependencies: 224
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (order_id, customer_id, order_date, total_amount) FROM stdin;
\.


--
-- TOC entry 4841 (class 0 OID 16562)
-- Dependencies: 220
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (product_id, name, category_id, price, stock_quantity) FROM stdin;
1	Смартфон	1	29999.99	50
2	Ноутбук	1	59999.99	30
3	Наушники	1	4999.99	100
4	Футболка	2	1999.99	200
5	Джинсы	2	3999.99	150
6	Роман "1984"	3	599.99	300
7	Учебник по SQL	3	1299.99	100
8	Диван	4	19999.99	20
9	Стул	4	2999.99	50
10	Лампа	4	999.99	100
11	Велосипед	5	15999.99	30
12	Мяч	5	1999.99	200
13	Часы	1	9999.99	80
14	Куртка	2	5999.99	120
15	Книга "Гарри Поттер"	3	899.99	250
16	Стол	4	7999.99	40
17	Тренажер	5	29999.99	15
18	Планшет	1	24999.99	60
19	Сумка	2	2999.99	180
20	Коврик для йоги	5	999.99	300
\.


--
-- TOC entry 4859 (class 0 OID 0)
-- Dependencies: 217
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 5, true);


--
-- TOC entry 4860 (class 0 OID 0)
-- Dependencies: 221
-- Name: customers_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_customer_id_seq', 1, false);


--
-- TOC entry 4861 (class 0 OID 0)
-- Dependencies: 225
-- Name: order_items_order_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_order_item_id_seq', 1, false);


--
-- TOC entry 4862 (class 0 OID 0)
-- Dependencies: 223
-- Name: orders_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_order_id_seq', 1, false);


--
-- TOC entry 4863 (class 0 OID 0)
-- Dependencies: 219
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_product_id_seq', 20, true);


--
-- TOC entry 4673 (class 2606 OID 16560)
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- TOC entry 4675 (class 2606 OID 16558)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4680 (class 2606 OID 16586)
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- TOC entry 4682 (class 2606 OID 16584)
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- TOC entry 4688 (class 2606 OID 16610)
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (order_item_id);


--
-- TOC entry 4685 (class 2606 OID 16595)
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- TOC entry 4678 (class 2606 OID 16569)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- TOC entry 4686 (class 1259 OID 16621)
-- Name: idx_order_items_order_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_order_product ON public.order_items USING btree (order_id, product_id);


--
-- TOC entry 4683 (class 1259 OID 16601)
-- Name: idx_orders_order_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_order_date ON public.orders USING btree (order_date);


--
-- TOC entry 4676 (class 1259 OID 16575)
-- Name: idx_products_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_products_name ON public.products USING btree (name);


--
-- TOC entry 4691 (class 2606 OID 16611)
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE CASCADE;


--
-- TOC entry 4692 (class 2606 OID 16616)
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- TOC entry 4690 (class 2606 OID 16596)
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;


--
-- TOC entry 4689 (class 2606 OID 16570)
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id) ON DELETE SET NULL;


-- Completed on 2025-02-07 14:07:12

--
-- PostgreSQL database dump complete
--

--
-- Database "storage_&_sells" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-02-07 14:07:12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4786 (class 1262 OID 41243)
-- Name: storage_&_sells; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "storage_&_sells" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';


ALTER DATABASE "storage_&_sells" OWNER TO postgres;

\connect -reuse-previous=on "dbname='storage_&_sells'"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Completed on 2025-02-07 14:07:13

--
-- PostgreSQL database dump complete
--

-- Completed on 2025-02-07 14:07:13

--
-- PostgreSQL database cluster dump complete
--


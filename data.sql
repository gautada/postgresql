-- sqlfluff:dialect:postgres
-- Step 2: Insert sample customers (100 customers)
INSERT INTO customers (first_name, last_name, email, phone) VALUES
('John', 'Doe', 'john.doe1@example.com', '555-0101'),
('Jane', 'Smith', 'jane.smith2@example.com', '555-0102'),
('Michael', 'Brown', 'michael.brown3@example.com', '555-0103'),
('Emily', 'Davis', 'emily.davis4@example.com', '555-0104'),
('Robert', 'Wilson', 'robert.wilson5@example.com', '555-0105'),
('Mary', 'Taylor', 'mary.taylor6@example.com', '555-0106'),
('William', 'Anderson', 'william.anderson7@example.com', '555-0107'),
('Linda', 'Thomas', 'linda.thomas8@example.com', '555-0108'),
('David', 'Jackson', 'david.jackson9@example.com', '555-0109'),
('Sarah', 'White', 'sarah.white10@example.com', '555-0110');
-- Add 90 more customers...

-- Step 3: Insert sample addresses (100 addresses)
INSERT INTO addresses (
    customer_id, street, city,
    state, zip_code, country
) VALUES
(1, '123 Main St', 'New York', 'NY', '10001', 'USA'),
(2, '456 Elm St', 'Los Angeles', 'CA', '90001', 'USA');
-- Add 98 more addresses...

-- Step 4: Insert sample products (50 products)
INSERT INTO products (name, price) VALUES
('Laptop', 999.99),
('Phone', 599.99),
('Headphones', 199.99),
('Tablet', 399.99),
('Smartwatch', 249.99),
('Keyboard', 89.99),
('Mouse', 49.99),
('Monitor', 299.99),
('Printer', 149.99),
('External Hard Drive', 129.99);
-- Add 40 more products...

-- Step 5: Insert sample orders
INSERT INTO orders (customer_id, total_amount) VALUES
(1, 1599.98),
(2, 999.99);

-- Step 6: Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 999.99),
(1, 2, 1, 599.99),
(2, 1, 1, 999.99);

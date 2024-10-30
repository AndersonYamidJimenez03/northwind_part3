# NorthWind Database (Part 3)

Part 3 of our projects with the NorthWind database focuses exclusively on working with and managing stored procedures. These, unlike user-defined functions (UDFs), are designed to perform tasks directly on the database—in other words, to make changes.

Stored procedures are built to handle transactions explicitly, manage exceptions, and allow for input and output parameters, unlike UDFs.

As previously mentioned in the Northwind Project Part 1 and 2, our database structure is a snowflake type, where our fact table is the "order_details" table, and the others are dimensional tables.

### The procedures requiered are:

1. Create a procedure to modify the first name of any employee given an employee ID.
2. Construct a procedure that will increase the price of a product due to inflation or any other price increase, given the product ID and the percentage increase for its price.
3. Generate a procedure to restore the price of the product modified in the previous step (number 2). Exceptions and transactions will be used to ensure data integrity and enforce ACID properties.
4. Develop a procedure that will incrementally increase the prices of products within a selected category using a cursor. This cursor will update the prices of categories below 5 according to the specified argument, and for categories 5 and above, an additional 10% increase will be applied by default. Lastly, to track who made the changes and the extent of each modification, every entry will be logged in the logs table.
5. Create a procedure that validates the stock quantity of a product, and if the quantity is greater than or equal to the requested amount, it will proceed to modify the database accordingly.

# Tools I used

These are the tools were used in this analysis:

- **PostgreSQL:** This was the chosen database management system for database creation, and its versatility enabled a strong connection with Visual Studio Code.
- **Visual Studio Code:** This is the most widely used code editor currently, and due to its high customizability, it was selected as the tool for writing queries.
- **Git & GitHub:** These tools were used in the project as version control applications, allowing for both local and remote storage and management of the project.

# Analysis

As mentioned earlier, this project focuses on the use of procedures and their various properties and functions. We will start with simpler procedures and gradually add other capabilities, such as transactions, exceptions, and the use of cursors.

1. Create a procedure to modify the first name of any employee given an employee ID.

```sql
CREATE OR REPLACE PROCEDURE updateNancysName()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET firstname = 'Nanncy'
    WHERE employeeid = 1;
END;
$$;

CALL updateNancysName();
```

This first procedure does not receive arguments; instead, it directly accesses the database to update the name of the employee with an ID of 1, changing their name to 'Nanncy'.

2. Construct a procedure that will increase the price of a product due to inflation or any other price increase, given the product ID and the percentage increase for its price.

```sql
CREATE OR REPLACE PROCEDURE updateProduct(
    id INT,
    percentageIncrease DECIMAL
) LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET unitprice = unitprice * (1 + percentageIncrease)
    WHERE productId = id;
END;
$$;

-- original values id: 3 and price: 10
CALL updateProduct(3, 0.2);

-- the database was modified new price: 12
SELECT productid, unitprice FROM products;
```

This procedure starts with two parameters: ID and percentage increase. The procedure uses these arguments to filter by the product ID and then apply the increase to the product’s unit price. Here’s how the procedure is called in the case of ID 3 with a 20% increase to its initial price of 10.

3. Generate a procedure to restore the price of the product modified in the previous step (number 2). Exceptions and transactions will be used to ensure data integrity and enforce ACID properties.

```sql
CREATE OR REPLACE PROCEDURE restoreProductPrice(
    id INT,
    originalPrice DECIMAL
) LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if id es negative
    IF id < 0 THEN
        RAISE EXCEPTION 'ID must be greater than zero';
    END IF;
    -- update query
    UPDATE products
    SET unitprice = originalPrice
    WHERE productId = id;

    -- check if the database was modified
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No product found with id: %', id;
    END IF;
    -- if there is not errors, it modifies de DB permantly
    -- COMMIT;

-- Exceptions block to manage others exceptions
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
        ROLLBACK;
END;
$$;

-- Retorn the original

CALL restoreProductPrice(3, 10);
CALL restoreProductPrice(0, 10);
CALL restoreProductPrice(-8, 10);

SELECT * FROM products;
```

In the previous procedure, two arguments are received: ID and original price. To perform the modification in the database, the product ID is first validated, which cannot be less than 0. It is also checked whether a modification was actually made in the database; for this, the variable 'FOUND' is used, which indicates if any changes occurred. According to the calls made to the procedure, the first one is executed without issues. The second, having a product ID of zero, proceeds to start the update, but since the 'FOUND' variable does not activate, we simply receive an exception indicating that the product was not found. Finally, with a negative ID, the initial exception was triggered directly.

4. Develop a procedure that will incrementally increase the prices of products within a selected category using a cursor. This cursor will update the prices of categories below 5 according to the specified argument, and for categories 5 and above, an additional 10% increase will be applied by default. Lastly, to track who made the changes and the extent of each modification, every entry will be logged in the logs table.

```sql

CREATE OR REPLACE PROCEDURE updateProductsByCategory(
    category_id INT,
    percentage_increment DECIMAL
) LANGUAGE plpgsql
AS $$
DECLARE
    record_row RECORD;
    cursor_element CURSOR FOR
        SELECT productid, unitprice, discontinued
        FROM products
        WHERE categoryid = category_id;
BEGIN
    IF category_id < 1 THEN
        RAISE EXCEPTION 'Category id: % not allow', category_id;
    END IF;

    OPEN cursor_element;

    LOOP
        FETCH cursor_element INTO record_row;
        EXIT WHEN NOT FOUND;
        /*
            Podemos hacer la logica a nivel individual de
            un sin fin de posibilidades

        */
        IF category_id < 5 THEN
            UPDATE products
            SET unitprice = record_row.unitprice * (1 + percentage_increment)
            WHERE productid = record_row.productid;
        ELSE
            -- incremento por default de 10% (por decreto)
            UPDATE products
            SET unitprice = record_row.unitprice * (1.1 + percentage_increment)
            WHERE productid = record_row.productid;
        END IF;

        -- insert into logs table --old price
        INSERT INTO logs(productId_log, unitprice_log, percentage_increment_log, user_log)
        VALUES
        (record_row.productId, record_row.unitprice, percentage_increment, SESSION_USER);
    END LOOP;

    CLOSE cursor_element;
END;
$$;

-- Check info before any change
SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 1;

-- call the procedure
CALL updateProductsByCategory(1, 0.2);

-- Observe the products from category 1 changed
SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 1;

-- Now, let's see category 7
SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 7;

-- call the procedure
CALL updateProductsByCategory(7, 0.1);

-- Observe the products from category 7 with a increment of 20% (because its category is greater than 4)
SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 7;

-- Check the table logs with all user and product information
SELECT * FROM logs;
```

This procedure implements the same functionalities as the previous procedure, such as argument validation and transactions. Additionally, a cursor is used to access each data entry at a granular level through a loop. Within the loop, validation is performed to determine which category is being addressed, and at the end, the modified data and the user who made the changes are recorded.

5. Create a procedure that validates the stock quantity of a product, and if the quantity is greater than or equal to the requested amount, it will proceed to modify the database accordingly.

```sql
CREATE OR REPLACE PROCEDURE inventaryControl(
    product_sold_id INT,
    quantity INT
) LANGUAGE plpgsql
AS $$
DECLARE inventaryQuantity INT := (SELECT unitsinstock FROM products WHERE productId = product_sold_id);
BEGIN

    -- Here, it checks if the company has the quantity
    -- require for the purchase
    IF inventaryQuantity < quantity THEN
        RAISE EXCEPTION 'There is not the quantity % of productId = % in stock', quantity, product_sold_id
            USING ERRCODE = 'C0001';
    END IF;

    -- update the new stock of product
    UPDATE products
    SET unitsinstock = unitsinstock - quantity
    WHERE productid = product_sold_id;


    --COMMIT;
EXCEPTION
    WHEN SQLSTATE 'C0001' THEN
        ROLLBACK;
        RAISE NOTICE '%', SQLERRM;
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Other error found';
END;
$$;

-- ProductId: 3 has 13 units in stock, so
-- this call will produce an exception
CALL inventaryControl(3, 15);

-- ProductId: 4 has 53 units in stock, so
-- this call will produce a sale and a new stock equal to 3
CALL inventaryControl(4, 50);
```

This final procedure is responsible for performing an initial validation and then modifying the stock quantities of a product before a purchase. It accepts the arguments of the product ID and the quantity to be purchased, and then makes the necessary modifications in the database. If a quantity greater than the available stock is requested, an exception will be raised to prevent the purchase.

# What I learned

As mentioned earlier, this project was entirely based on the use and management of procedures. This allowed me to delve into multiple aspects (though there is still more to learn), such as exceptions, parameter types, clauses for modifying the database, transactions, and finally, the use of cursors to make modifications at a granular level and gain more detailed access to each record within the cursor.

Without a doubt, I learned many things through this project, which has given me new ideas for future projects and an opportunity to continue improving my SQL knowledge.

## Closing Thoughts

This project gave me insight into understanding the use of procedures and their differences from user-defined functions (UDFs). Beyond the potential of procedures for performing repetitive tasks in the database, the most important aspect is knowing when to use them. For example, in the procedure called 'inventoryControl', which should be executed at the initial stage of a product purchase, it performs the necessary validation of stock quantities. After purchase approval, it decreases the quantities in the database, thereby protecting data integrity and consistency. This demonstrates that the correct timing for using procedures is crucial.

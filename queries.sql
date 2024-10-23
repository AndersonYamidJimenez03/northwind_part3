/* 
    Procedure para iniciar con una actualizacion de
    un nombre particular del empleado con 
    employeeID numero 1
*/

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

SELECT * FROM employees;

/* 
    Procedure que actualizara el anual dada la inflacion de un producto particular
*/ 
SELECT * FROM products;

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

/*
    Procedure que restaurara el valor inicial del producto
    id: 3 a su precio original price: 10, y se estableceran exceptiones y transactiones para asegurarnos de la integridad de la base de datos gracias a las propiedades ACID
*/

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


/*
    Procedure para aumentar el precio de todos los productos
    de cierta categoria segun el porcentaje que tomara el procedure como argumento

*/




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

SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 1;

CALL updateProductsByCategory(1, 0.2);

SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 1;

SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 7;

CALL updateProductsByCategory(7, 0.1);

SELECT productid, unitprice, categoryid
FROM products
WHERE categoryid = 7;

SELECT * FROM logs;

ROLLBACK;








/*

CREATE OR REPLACE PROCEDURE promote_employee(emp_id INT, new_position VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM employees WHERE id = emp_id AND position != new_position) THEN
        UPDATE employees
        SET position = new_position
        WHERE id = emp_id;
        RAISE NOTICE 'Employee promoted to %', new_position;
    ELSE
        RAISE NOTICE 'No change needed';
    END IF;
END;
$$;
*/
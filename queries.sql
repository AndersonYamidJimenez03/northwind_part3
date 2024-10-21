/* 
    Procedure para iniciar con una actualizacion de
    un nombre particular del empleado con 
    employeeID numero 1
*/

CREATE OR REPLACE PROCEDURE getCategoriesTable()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET firstname = 'Nanncy'
    WHERE employeeid = 1;
END;
$$;

CALL getCategoriesTable();

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


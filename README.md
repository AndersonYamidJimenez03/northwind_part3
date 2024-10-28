# NorthWind Database (Part 3)

La parte 3 de nuestros projectos con la base de datos NorthWind, se basa exclusivamente al trabajo y manejo de los procedures. Estos a diferencia de las user-defined functions (UDF) estan disenadas para hacer tareas directamente en la base de datos, dicho de otro modo para realizar cambios.

Los procedures estan construidos para manejar transactiones de forma explicita, gestionar exceptiones y permitir parametros de entrada y salida contrario a las UDF.

As previously mentioned in the Northwind Project Part 1 and 2, our database structure is a snowflake type, where our fact table is the "order_details" table, and the others are dimensional tables.

### The procedures requiered are:

1. Creation de un procedure para modificar el primer nombre de cualquier empleado dado un Id de empleado.
2. Construction de un procedure el cual se encargara de aumentar el valor de un producto ya sea por inflacion o por otro aumento, dado el id de producto y el porcentaje de incremento para su precio.
3. Generar un procedure para restaurar el valor del producto modificado en el punto anterior (numero 2). para lo cual se utilizara exceptiones y transactiones para garantizar la integrirar de los datos y el uso de propiedades ACID.
4. Desarrollar un procedure que incrementara porcentualmente los productos dentro de una categoria selectionada por medio de un cursor, el cual actualizara el valor de las categorias menores a 5 segun el argumento compartido y para las categorias mayores o iguales a 5 se les adicionara otro aumento del 10% por defecto. Por ultimo, para validar quien realizo que cambios y su magnitud se adicionara cada registro en la tabla logs.
5. Create un procedure que valide la cantidad de stock de un producto y en caso de que la cantidad sea mayor o igual a la cantidad demandada entonces realizar la modificacion en la base de datos.

# Tools I used

These are the tools were used in this analysis:

- **PostgreSQL:** This was the chosen database management system for database creation, and its versatility enabled a strong connection with Visual Studio Code.
- **Visual Studio Code:** This is the most widely used code editor currently, and due to its high customizability, it was selected as the tool for writing queries.
- **Git & GitHub:** These tools were used in the project as version control applications, allowing for both local and remote storage and management of the project.

# Analysis

Como se menciono anteriormente, este projecto se centra en el uso de procedures y sus diferentes propiedades y funciones. Iniciaremos procedures mas siemples y se buscara ir adicionando otras capacidades como transactiones, exceptiones y uso de cursor.

1. Creation de un procedure para modificar el primer nombre de cualquier empleado dado un Id de empleado.

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

Este primer procedure no recibe argumentos, sino que directamente va a la base de datos para actualizar el nombre del empleado con id igual a 1. Y posteriormente modificar su nombre a 'Nanncy'.

2. Construction de un procedure el cual se encargara de aumentar el valor de un producto ya sea por inflacion o por otro aumento, dado el id de producto y el porcentaje de incremento para su precio.

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

Este procedure empieza con dos parametros; id y incremento porcentual. El procedure toma estos argumentos para filtar por el Id del producto y luego para realizar el incremento al precio unitario del producto. Asi es como se llama el procedure en el caso de el id: 3 e incremento del 20% a su precio unicial de 10.

3. Generar un procedure para restaurar el valor del producto modificado en el punto anterior (numero 2). para lo cual se utilizara exceptiones y transactiones para garantizar la integrirar de los datos y el uso de propiedades ACID.

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

En el anterior procedure, reciben dos argumentos id y precio original. Y para realizar la modificacion en la base de datos, inicialmente se valida el valor de id del producto el cual no puede ser menor de 0. Pero tambien se valida si realmente se genero una modificacion en la base de datos por eso se usa la variable 'FOUND', la cual nos indica si se produjo algun cambio. Segun las llamadas realizadas al procedure, la primera se realiza sin problema, la segunda al tener un id de producto igual a cero, procede a iniciar la actualizacion, pero al no activarse la variable 'FOUND', simplemente recibimos la exception de que el producto no se encontro. Y por ultimo, el id al ser negativo directamente la exception inicial fue inicializada.

4. Desarrollar un procedure que incrementara porcentualmente los productos dentro de una categoria selectionada por medio de un cursor, el cual actualizara el valor de las categorias menores a 5 segun el argumento compartido y para las categorias mayores o iguales a 5 se les adicionara otro aumento del 10% por defecto. Por ultimo, para validar quien realizo que cambios y su magnitud se adicionara cada registro en la tabla logs.

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

Este procedure implementa las mismas funcionalidades del procedure como validacion de argumentos y transaciones. Adicionalmente, se utiliza un cursor para ir a cada dato a nivel granular por medio de un loop. Dentro del loop se realiza la validacion de cual categoria en cuestion y al final se registra los datos modificados y el usuario que realizo los cambios.

5. Create un procedure que valide la cantidad de stock de un producto y en caso de que la cantidad sea mayor o igual a la cantidad demandada entonces realizar la modificacion en la base de datos.

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

SELECT * FROM products;
```

# What I learned

## Closing Thoughts

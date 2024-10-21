/* 
 Let's going to create all tables belonging to NorthWind Database
 */


-- First table validations and drop if they already exists
DROP TABLE IF EXISTS orders_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS employee_territories;
DROP TABLE IF EXISTS territories;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS shippers;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;


-- tables' creation

-- employees table
CREATE TABLE employees(
    employeeId int NOT NULL,
    lastname varchar(15),
    firstname varchar(15),
    title varchar(30),
    titleofcourtesy varchar(25),
    birthdate date,
    hiredate date,
    address varchar(60),
    city varchar(15),
    region varchar(20),
    postalcode varchar(15),
    country varchar(20),
    homephone varchar(15),
    extension varchar(15),
    photo bytea,
    notes text,
    reportsto int,
    photopath varchar(255),
    constraint pk_employees PRIMARY KEY(employeeId)
); 

-- customer table
CREATE TABLE customers (
    customerId varchar(10) NOT NULL,
    companyname varchar(40) NOT NULL,
    contactname varchar(30),
    contacttitle varchar(30),
    city varchar(20),
    region varchar(20),
    postalcode varchar(15),
    country varchar(20),
    phone varchar(20),
    fax varchar(20),
    constraint pk_customers PRIMARY KEY (customerId)
);

-- shippres table
CREATE TABLE shippers(
    shipperId int NOT NULL,
    companyname varchar(20),
    phone varchar(20),
    constraint pk_shippers PRIMARY KEY(shipperId)
);

-- regions table
CREATE TABLE regions(
    regionId int NOT NULL,
    regiondescription varchar(15),
    constraint pk_regions PRIMARY KEY(regionId)
); 

-- territories table 
CREATE TABLE territories(
    territoryId int NOT NULL,
    territorydescription varchar(20),
    regionId int NOT NULL,
    constraint pk_territories PRIMARY KEY(territoryId),
    constraint fk_territories_regions FOREIGN KEY(regionId) REFERENCES regions(regionId)
);

-- employee_territories table
CREATE TABLE employee_territories (
    employeeId int NOT NULL,
    territoryId int,
    constraint pk_employee_territories PRIMARY KEY(employeeId, territoryId),
    constraint fk_employee_territories_employees FOREIGN KEY (employeeId) REFERENCES employees (employeeId),
    constraint fk_employee_territories_territories FOREIGN KEY (territoryId) REFERENCES territories (territoryId)
); 

-- categories table
CREATE TABLE categories (
    categoryId int NOT NULL,
    categoryname varchar(25) NOT NULL,
    description text,
    picture bytea,
    constraint pk_categories PRIMARY KEY (categoryId)
);

-- suppliers table 
CREATE TABLE suppliers(
    supplierId int NOT NULL,
    companyname varchar(40),
    contactname varchar(30),
    contacttitle varchar(30),
    address varchar(50),
    city varchar(15),
    region varchar(20),
    postalcode varchar(15),
    country varchar(15),
    phone varchar(15),
    fax varchar(15),
    homepage text,
    constraint pk_suppliers PRIMARY KEY(supplierId)
);

-- order products table
CREATE TABLE products(
    productId int NOT NULL,
    productname varchar(40),
    supplierId int NOT NULL,
    categoryId int NOT NULL,
    quantityperunit varchar(25),
    unitprice decimal,
    unitsinstock int,
    unitsonorder int,
    reorderlevel int,
    discontinued int,
    constraint pk_products PRIMARY KEY(productId),
    constraint fk_products_suppliers FOREIGN KEY(supplierId) REFERENCES suppliers(supplierId),
    constraint fk_products_categories FOREIGN KEY (categoryId) REFERENCES categories (categoryId)
);



-- orders table
CREATE TABLE orders(
    orderId int NOT NULL,
    customerId varchar(10) NOT NULL,
    employeeId int NOT NULL,
    orderdate date,
    requireddate date,
    shippeddate date,
    shipperId int NOT NULL,
    freight decimal,
    shipname varchar(40),
    shipcity varchar(15),
    shipregion varchar(15),
    shippostalcode varchar(15),
    shipcountry varchar(15),
    constraint pk_orders PRIMARY KEY(orderId),
    constraint fk_orders_customers FOREIGN KEY(customerId) REFERENCES customers (customerId),
    constraint fk_orders_employees FOREIGN KEY(employeeId) REFERENCES employees (employeeId),
    constraint fk_orders_shippers FOREIGN KEY(shipperId) REFERENCES shippers (shipperId)
);

-- orders_details table
CREATE TABLE orders_details(
    orderId int NOT NULL,
    productId int NOT NULL,
    unitprice decimal,
    quantity int,
    discount decimal,
    constraint pk_orders_details PRIMARY KEY(orderId, productId),
    constraint fk_orders_details_orders FOREIGN KEY (orderId) REFERENCES orders (orderId),
    constraint fk_orders_details_products FOREIGN KEY (productId) REFERENCES products(productId)
); 

-- tables owership
ALTER TABLE categories OWNER TO postgres;
ALTER TABLE customers OWNER TO postgres;
ALTER TABLE employee_territories OWNER TO postgres;
ALTER TABLE employees OWNER TO postgres;
ALTER TABLE orders_details OWNER TO postgres;
ALTER TABLE orders OWNER TO postgres;
ALTER TABLE products OWNER TO postgres;
ALTER TABLE regions OWNER TO postgres;
ALTER TABLE shippers OWNER TO postgres;
ALTER TABLE suppliers OWNER TO postgres;
ALTER TABLE territories OWNER TO postgres;
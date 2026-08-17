CREATE TABLE stores (
    store_id VARCHAR(10) PRIMARY KEY
);

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY
);

CREATE TABLE daily_operations (
    date DATE NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,

    category VARCHAR(50),
    region VARCHAR(50),

    inventory_level INT NOT NULL,
    units_sold INT NOT NULL,
    units_ordered INT NOT NULL,

    demand_forecast DECIMAL(10,2),
    price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(5,2),
    competitor_pricing DECIMAL(10,2),

    weather_condition VARCHAR(50),
    holiday_promotion INT,
    seasonality VARCHAR(50),

    PRIMARY KEY (date, store_id, product_id),

    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
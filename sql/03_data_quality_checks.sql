-- 1. Negative demand forecasts
SELECT COUNT(*) AS negative_forecast_count
FROM daily_operations
WHERE demand_forecast < 0;

-- 2. Zero sales
SELECT COUNT(*) AS zero_sales_count
FROM daily_operations
WHERE units_sold = 0;

-- 3. Zero inventory
SELECT COUNT(*) AS zero_inventory_count
FROM daily_operations
WHERE inventory_level = 0;

-- 4. Sales greater than inventory
SELECT COUNT(*) AS sales_exceed_inventory_count
FROM daily_operations
WHERE units_sold > inventory_level;

-- 5. Negative operational values
SELECT COUNT(*) AS negative_operational_values
FROM daily_operations
WHERE inventory_level < 0
   OR units_sold < 0
   OR units_ordered < 0
   OR price < 0
   OR competitor_pricing < 0;

-- 6. Distribution of negative forecasts by category
SELECT
    category,
    COUNT(*) AS negative_forecast_count
FROM daily_operations
WHERE demand_forecast < 0
GROUP BY category
ORDER BY negative_forecast_count DESC;
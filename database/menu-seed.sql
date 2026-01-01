-- Sample Menu Data
-- Run this after schema.sql to populate menu items

INSERT INTO menu_items (name, description, category, price, is_vegetarian, is_available) VALUES
-- Starters
('Paneer Tikka', 'Cottage cheese marinated in spices and grilled to perfection', 'Starters', 220.00, true, true),
('Chicken Tikka', 'Boneless chicken pieces marinated in yogurt and spices', 'Starters', 280.00, false, true),
('Veg Spring Rolls', 'Crispy rolls filled with fresh vegetables', 'Starters', 180.00, true, true),
('Fish Fingers', 'Crispy fried fish strips served with tartar sauce', 'Starters', 320.00, false, true),
('Mushroom 65', 'Spicy fried mushrooms tossed in special masala', 'Starters', 240.00, true, true),

-- Main Course
('Butter Chicken', 'Tender chicken in rich tomato and butter gravy', 'Main Course', 380.00, false, true),
('Dal Makhani', 'Creamy black lentils slow-cooked overnight', 'Main Course', 280.00, true, true),
('Paneer Butter Masala', 'Cottage cheese in creamy tomato gravy', 'Main Course', 320.00, true, true),
('Biryani (Veg)', 'Aromatic basmati rice with vegetables and spices', 'Main Course', 280.00, true, true),
('Biryani (Chicken)', 'Aromatic basmati rice with chicken and spices', 'Main Course', 350.00, false, true),
('Fish Curry', 'Fresh fish cooked in coconut-based curry', 'Main Course', 420.00, false, true),
('Chole Bhature', 'Spicy chickpeas with fluffy fried bread', 'Main Course', 250.00, true, true),

-- Breads
('Butter Naan', 'Soft leavened bread brushed with butter', 'Breads', 60.00, true, true),
('Garlic Naan', 'Naan topped with garlic and coriander', 'Breads', 80.00, true, true),
('Tandoori Roti', 'Whole wheat flatbread from tandoor', 'Breads', 40.00, true, true),
('Laccha Paratha', 'Multi-layered crispy flatbread', 'Breads', 70.00, true, true),

-- Rice
('Jeera Rice', 'Basmati rice tempered with cumin', 'Rice', 150.00, true, true),
('Steamed Rice', 'Plain steamed basmati rice', 'Rice', 120.00, true, true),

-- Desserts
('Gulab Jamun', 'Soft milk dumplings in sugar syrup (2 pieces)', 'Desserts', 80.00, true, true),
('Rasgulla', 'Spongy cottage cheese balls in syrup (3 pieces)', 'Desserts', 90.00, true, true),
('Kulfi', 'Traditional Indian ice cream', 'Desserts', 100.00, true, true),
('Gajar Halwa', 'Sweet carrot pudding with nuts', 'Desserts', 120.00, true, true),

-- Beverages
('Mango Lassi', 'Creamy mango yogurt drink', 'Beverages', 80.00, true, true),
('Sweet Lassi', 'Traditional sweet yogurt drink', 'Beverages', 60.00, true, true),
('Masala Chaas', 'Spiced buttermilk', 'Beverages', 50.00, true, true),
('Soft Drink', 'Coke/Pepsi/Sprite', 'Beverages', 40.00, true, true),
('Mineral Water', '1 Liter bottle', 'Beverages', 30.00, true, true);

-- Verify insertion
SELECT category, COUNT(*) as item_count, 
       AVG(price) as avg_price,
       MIN(price) as min_price,
       MAX(price) as max_price
FROM menu_items
GROUP BY category
ORDER BY category;
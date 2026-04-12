-- =========================================================================
-- BẢN VÁ 4: ĐỔ DỮ LIỆU MẪU (MOCK DATA) CHO NHÀ HÀNG & KHUYẾN MÃI
-- Hãy copy toàn bộ đoạn mã này và chạy trên góc SQL Editor của Supabase.
-- =========================================================================

-- 1. XOÁ DỮ LIỆU CŨ NẾU CẦN (KHUYẾN CÁO KHÔNG CHẠY NẾU KHÔNG MUỐN MẤT DATA CŨ)
-- TRUNCATE TABLE public.restaurants CASCADE;
-- TRUNCATE TABLE public.promotions CASCADE;

-- 2. TẠO 30 NHÀ HÀNG MẪU (THUẦN VIỆT & ĐA DẠNG)
INSERT INTO public.restaurants (name, rating, delivery_fee, image_url, tags, is_online) VALUES
('Cơm Tấm Cali', 4.8, '15.000đ', 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=500&q=80', ARRAY['Cơm', 'Đồ Việt', 'Món chính'], true),
('Highlands Coffee', 4.5, '10.000đ', 'https://images.unsplash.com/photo-1559525839-b184a4d698c7?w=500&q=80', ARRAY['Thức uống', 'Cà phê', 'Bánh ngọt'], true),
('Gà Rán KFC', 4.2, '20.000đ', 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&q=80', ARRAY['Đồ ăn nhanh', 'Gà rán'], true),
('Phở Hùng', 4.6, '15.000đ', 'https://images.unsplash.com/photo-1582878826629-29b7ad1cb431?w=500&q=80', ARRAY['Đồ Việt', 'Món nước'], true),
('Trà Sữa Gong Cha', 4.9, 'Miễn phí', 'https://images.unsplash.com/photo-1558857563-b37f3eb00b1a?w=500&q=80', ARRAY['Thức uống', 'Trà sữa'], true),
('Bún Bò Huế 3A3', 4.7, '25.000đ', 'https://images.unsplash.com/photo-1596622528771-13acb4ee3f7e?w=500&q=80', ARRAY['Đồ Việt', 'Món nước', 'Bún bò'], true),
('Pizza Hut', 4.1, '30.000đ', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&q=80', ARRAY['Pizza', 'Đồ Âu', 'Fast Food'], true),
('Cơm Niêu Singapore', 4.5, '15.000đ', 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500&q=80', ARRAY['Cơm', 'Món chua ngọt'], true),
('Bánh Mì Huynh Hoa', 5.0, '20.000đ', 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=500&q=80', ARRAY['Bánh mì', 'Ăn nhẹ'], true),
('Lẩu Bò Tí Chuột', 4.6, 'Miễn phí', 'https://images.unsplash.com/photo-1548943487-a2e4143f485e?w=500&q=80', ARRAY['Lẩu', 'Món nhậu'], true),
('Soya Garden', 4.3, '10.000đ', 'https://images.unsplash.com/photo-1510626176961-4b57d4fbad03?w=500&q=80', ARRAY['Healthy', 'Đồ ăn chay', 'Thức uống'], false),
('Chè Thái Ý Phương', 4.4, '15.000đ', 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=500&q=80', ARRAY['Đồ ngọt', 'Tráng miệng'], true),
('Don Chicken', 4.8, '25.000đ', 'https://images.unsplash.com/photo-1626082928540-c3d3962b8cf1?w=500&q=80', ARRAY['Gà rán', 'Món Hàn'], true),
('Haidilao Hotpot', 5.0, '50.000đ', 'https://images.unsplash.com/photo-1605335661608-f1cda0807b5a?w=500&q=80', ARRAY['Lẩu', 'Cao cấp', 'Món Trung'], true),
('Nem Nướng Ninh Hòa', 4.7, '15.000đ', 'https://images.unsplash.com/photo-1533745848184-3db07256e163?w=500&q=80', ARRAY['Món cuốn', 'Đặc sản'], true),
('Kichi Kichi', 4.5, '20.000đ', 'https://images.unsplash.com/photo-1582878826629-29b7ad1cb431?w=500&q=80', ARRAY['Lẩu', 'Buffet'], true),
('Tocotoco', 4.2, '10.000đ', 'https://images.unsplash.com/photo-1558857563-b37f3eb00b1a?w=500&q=80', ARRAY['Thức uống', 'Trà sữa'], true),
('Bún Đậu Mắm Tôm A Chảnh', 4.6, '20.000đ', 'https://images.unsplash.com/photo-1563227812-0ea4c22e6cc8?w=500&q=80', ARRAY['Món Việt', 'Món truyền thống'], true),
('Otoké Chicken', 4.3, '15.000đ', 'https://images.unsplash.com/photo-1562967914-6014dc5f3969?w=500&q=80', ARRAY['Gà rán', 'Ăn vặt'], true),
('Cháo Sườn Chú Chen', 4.8, 'Miễn phí', 'https://images.unsplash.com/photo-1628198539088-75704bbd5db3?w=500&q=80', ARRAY['Món nước', 'Ăn nhẹ', 'Cháo'], true),
('Texas Chicken', 4.4, '20.000đ', 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&q=80', ARRAY['Gà rán', 'Đồ ăn nhanh'], true),
('Thái Express', 4.6, '25.000đ', 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=500&q=80', ARRAY['Món Thái', 'Đồ cay'], true),
('Bò Né 3 Ngon', 4.7, '10.000đ', 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500&q=80', ARRAY['Thịt bò', 'Bữa sáng'], true),
('Burger McDonald''s', 4.5, '20.000đ', 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=500&q=80', ARRAY['Burger', 'Đồ ăn nhanh'], true),
('Mì Cay Naga', 4.3, '15.000đ', 'https://images.unsplash.com/photo-1552611052-33e04de081de?w=500&q=80', ARRAY['Mì cay', 'Món Hàn'], true),
('Súp Cua Hạnh', 4.8, '10.000đ', 'https://images.unsplash.com/photo-1600868853702-8bd0cfad73b2?w=500&q=80', ARRAY['Súp', 'Ăn nhẹ'], true),
('Sữa Chua Trân Châu Hạ Long', 4.5, '10.000đ', 'https://images.unsplash.com/photo-1488477304112-4944851de03d?w=500&q=80', ARRAY['Tráng miệng', 'Thức uống'], true),
('Mixue', 4.9, 'Miễn phí', 'https://images.unsplash.com/photo-1563805042-7684c8a9e9ce?w=500&q=80', ARRAY['Kem', 'Trà'], true),
('Nhà Hàng Chay Hoa Đăng', 4.7, '20.000đ', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80', ARRAY['Ăn chay', 'Healthy'], true),
('Gà Nướng Ò Ó O', 4.6, '15.000đ', 'https://images.unsplash.com/photo-1598514982205-f36b96d1e8d4?w=500&q=80', ARRAY['Gà nướng', 'Món chính'], true);


-- 3. TẠO 30 MÃ KHUYẾN MÃI (VOUCHERS)
INSERT INTO public.promotions (code, discount_percentage, max_discount, min_order_value, expiration_date, is_active) VALUES
('XINCHAO', 50.0, 50000, 0, NOW() + INTERVAL '30 days', true),
('FREESHIP99', 100.0, 15000, 99000, NOW() + INTERVAL '10 days', true),
('THU2VUI', 20.0, 30000, 100000, NOW() + INTERVAL '7 days', true),
('SIEUSALE10', 10.0, 20000, 50000, NOW() + INTERVAL '3 days', true),
('CUOITUAN', 15.0, 25000, 150000, NOW() + INTERVAL '2 days', true),
('BOSSCUNG', 100.0, 20000, 0, NOW() + INTERVAL '15 days', true),
('MUA1TANG1', 50.0, 40000, 80000, NOW() + INTERVAL '60 days', true),
('CHAOBANMOI', 30.0, 60000, 100000, NOW() + INTERVAL '100 days', true),
('GIAMSAU', 40.0, 100000, 200000, NOW() + INTERVAL '5 days', true),
('TIECGIADINH', 25.0, 80000, 300000, NOW() + INTERVAL '30 days', true),
('GIAOHANG0D', 100.0, 25000, 150000, NOW() + INTERVAL '15 days', true),
('KHUYENMAI20', 20.0, 35000, 120000, NOW() + INTERVAL '12 days', true),
('NGONQUATA', 15.0, 50000, 250000, NOW() + INTERVAL '9 days', true),
('ĂNNO', 10.0, 15000, 80000, NOW() + INTERVAL '7 days', true),
('TIFFIN20', 20.0, 20000, 50000, NOW() + INTERVAL '5 days', true),
('CRAVING50', 50.0, 50000, 100000, NOW() + INTERVAL '3 days', true),
('SUMMERVIBE', 25.0, 30000, 100000, NOW() + INTERVAL '30 days', true),
('RAINYDAY', 15.0, 20000, 70000, NOW() + INTERVAL '15 days', true),
('NIGHTOWL', 30.0, 40000, 120000, NOW() + INTERVAL '20 days', true),
('EARLYBIRD', 20.0, 25000, 80000, NOW() + INTERVAL '25 days', true),
('HOTDEAL', 40.0, 60000, 150000, NOW() + INTERVAL '2 days', true),
('LUNCHTIME', 15.0, 30000, 100000, NOW() + INTERVAL '5 days', true),
('DINNERDATE', 20.0, 40000, 200000, NOW() + INTERVAL '8 days', true),
('FAMILYBOX', 10.0, 50000, 300000, NOW() + INTERVAL '12 days', true),
('PARTYTIME', 35.0, 100000, 400000, NOW() + INTERVAL '7 days', true),
('WEEKENDCHILL', 25.0, 45000, 150000, NOW() + INTERVAL '3 days', true),
('MONDAYBLUES', 15.0, 20000, 60000, NOW() + INTERVAL '1 days', true),
('TACOTACO', 30.0, 30000, 100000, NOW() + INTERVAL '4 days', true),
('PIZZA50', 50.0, 50000, 100000, NOW() + INTERVAL '14 days', true),
('SUSHIYESS', 20.0, 60000, 250000, NOW() + INTERVAL '21 days', true);

-- =========================================================================
-- 4. TẠO 30 NGƯỜI DÙNG (15 KHÁCH HÀNG, 15 TÀI XẾ) VÀO CẢ BẢNG AUTH VÀ PUBLIC
-- =========================================================================
DO $$
DECLARE
    new_user_id UUID;
    i INT;
BEGIN
    -- Tạo 15 Khách Hàng
    FOR i IN 1..15 LOOP
        new_user_id := gen_random_uuid();
        -- Chèn vào auth.users (Bảng ẩn của Supabase)
        INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
        VALUES (new_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'customer_mock_' || i || '@test.com', 'hashed_pass_placeholder', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());
        
        -- Chèn vào public.users
        INSERT INTO public.users (id, email, name, role, is_approved, wallet_balance)
        VALUES (new_user_id, 'customer_mock_' || i || '@test.com', 'Khách hàng Ảo ' || i, 'customer', true, FLOOR(RANDOM() * 500000) + 50000);
    END LOOP;
    
    -- Tạo 15 Tài Xế
    FOR i IN 1..15 LOOP
        new_user_id := gen_random_uuid();
        INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
        VALUES (new_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'driver_mock_' || i || '@test.com', 'hashed_pass_placeholder', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());
        
        INSERT INTO public.users (id, email, name, role, is_approved, wallet_balance, rating, completed_rides)
        VALUES (new_user_id, 'driver_mock_' || i || '@test.com', 'Tài xế Ảo ' || i, 'driver', true, FLOOR(RANDOM() * 200000), ROUND((RANDOM() * 1.5 + 3.5)::numeric, 1), FLOOR(RANDOM() * 100));
    END LOOP;
END $$;

-- =========================================================================
-- 5. TẠO 30 ĐƠN HÀNG (TRỘN NGẪU NHIÊN USER & RESTAURANT)
-- =========================================================================
INSERT INTO public.orders (customer_id, driver_id, merchant_id, merchant_name, merchant_image, service_type, status, total_price, address, items_summary, created_at)
SELECT 
    (SELECT id FROM public.users WHERE role = 'customer' ORDER BY random() LIMIT 1) as customer_id,
    (SELECT id FROM public.users WHERE role = 'driver' ORDER BY random() LIMIT 1) as driver_id,
    r.id as merchant_id,
    r.name as merchant_name,
    r.image_url as merchant_image,
    (ARRAY['Food', 'Ride', 'Mart', 'Courier'])[floor(random() * 4 + 1)] as service_type,
    (ARRAY['Pending', 'Accepted', 'InProgress', 'Completed', 'Cancelled'])[floor(random() * 5 + 1)] as status,
    FLOOR(RANDOM() * 200000) + 30000 as total_price,
    'Số ' || FLOOR(RANDOM() * 100) || ' Đường Giả, Quận Ảo, TP.HCM' as address,
    (ARRAY['2x Pizza, 1x Coca', 'Chuyến xe đi học', 'Mua giúp trái cây', 'Đem giấy tờ lên Cty'])[floor(random() * 4 + 1)] as items_summary,
    NOW() - (random() * interval '30 days') as created_at
FROM generate_series(1, 30)
CROSS JOIN LATERAL (SELECT id, name, image_url FROM public.restaurants ORDER BY random() LIMIT 1) r;

-- =========================================================================
-- 6. TẠO 30 LỊCH SỬ GIAO DỊCH VÍ (TRANSACTIONS)
-- =========================================================================
INSERT INTO public.transactions (user_id, amount, type, description, created_at)
SELECT 
    (SELECT id FROM public.users ORDER BY random() LIMIT 1),
    FLOOR(RANDOM() * 500000) + 10000,
    (ARRAY['top_up', 'transfer_in', 'transfer_out', 'Ride', 'Food'])[floor(random() * 5 + 1)],
    'Giao dịch mẫu',
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 30);

-- =========================================================================
-- 7. TẠO 30 PHIÊN CHAT AI (CHAT SESSIONS)
-- =========================================================================
INSERT INTO public.chat_sessions (user_id, topic, last_message, created_at)
SELECT 
    (SELECT id FROM public.users ORDER BY random() LIMIT 1),
    (ARRAY['Hỗ trợ đặt xe', 'Gợi ý món ăn', 'Thắc mắc cước phí', 'Báo lỗi ứng dụng'])[floor(random() * 4 + 1)],
    'Cảm ơn bạn đã phản hồi.',
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 30);

-- =========================================================================
-- 8. TẠO 30 TIN NHẮN TRONG PHIÊN CHAT AI
-- =========================================================================
INSERT INTO public.messages (session_id, user_id, text, is_from_user, created_at)
SELECT 
    session_id,
    user_id,
    (ARRAY['Xin chào, SuperApp AI có thể giúp gì?', 'Tìm cho tôi nhà hàng bán pizza ngon', 'Quán Pizza Hut đang có khuyến mãi', 'Cảm ơn bạn.'])[floor(random() * 4 + 1)],
    (random() > 0.5),
    session_created_at + (random() * interval '5 minutes')
FROM (
    SELECT 
        id as session_id,
        user_id,
        created_at as session_created_at
    FROM public.chat_sessions
    ORDER BY random()
    LIMIT 30
) sub;

-- ĐÃ XONG TOÀN BỘ 7 BẢNG DỮ LIỆU! 🚀

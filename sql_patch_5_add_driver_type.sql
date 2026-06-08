-- Thêm cột driver_type vào bảng users để hỗ trợ lưu trữ loại hãng xe của tài xế (Grab, Be, Xanh SM)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS driver_type TEXT;

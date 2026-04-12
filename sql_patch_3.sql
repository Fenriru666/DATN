-- Bổ sung các cột bị thiếu vào bảng public.users cho vừa khớp với UserModel

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS rating NUMERIC DEFAULT 5.0,
ADD COLUMN IF NOT EXISTS rating_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS completed_rides INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS referral_code TEXT,
ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES public.users(id),
ADD COLUMN IF NOT EXISTS favorite_drivers TEXT[],
ADD COLUMN IF NOT EXISTS saved_places JSONB;

-- Cập nhật Role Policy nếu cần
-- Cập nhật logic để user có thể nạp/lưu trạng thái ưa thích mà không bị lỗi.

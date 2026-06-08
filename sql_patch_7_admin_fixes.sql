-- Fix: Admin role is stored as 'customer' due to DB check constraint, 
-- so we check email LIKE 'admin%' instead.

-- 1. Cập nhật lại Hàm RPC phê duyệt đối tác
CREATE OR REPLACE FUNCTION admin_approve_user(p_user_id TEXT) RETURNS VOID AS $$
DECLARE
  v_caller_email TEXT;
BEGIN
  -- Lấy email của người gọi
  SELECT email INTO v_caller_email FROM public.users WHERE id = auth.uid();
  
  IF v_caller_email NOT LIKE 'admin%' THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can approve users';
  END IF;

  UPDATE public.users SET is_approved = true WHERE id = p_user_id::uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Cập nhật lại Hàm RPC đình chỉ đối tác
CREATE OR REPLACE FUNCTION admin_ban_user(p_user_id TEXT) RETURNS VOID AS $$
DECLARE
  v_caller_email TEXT;
BEGIN
  SELECT email INTO v_caller_email FROM public.users WHERE id = auth.uid();
  
  IF v_caller_email NOT LIKE 'admin%' THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can ban users';
  END IF;

  UPDATE public.users SET is_approved = false WHERE id = p_user_id::uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Bật RLS và cấp quyền cho Admin trên bảng promotions
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can do everything on promotions" ON public.promotions;
CREATE POLICY "Admins can do everything on promotions" 
ON public.promotions 
FOR ALL 
USING ( (SELECT email FROM public.users WHERE id = auth.uid()) LIKE 'admin%' ) 
WITH CHECK ( (SELECT email FROM public.users WHERE id = auth.uid()) LIKE 'admin%' );

DROP POLICY IF EXISTS "Anyone can view promotions" ON public.promotions;
CREATE POLICY "Anyone can view promotions" 
ON public.promotions FOR SELECT USING (true);

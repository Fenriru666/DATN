-- Hàm RPC để Admin phê duyệt đối tác
CREATE OR REPLACE FUNCTION admin_approve_user(p_user_id TEXT) RETURNS VOID AS $$
DECLARE
  v_caller_role TEXT;
BEGIN
  -- Lấy role của người gọi
  SELECT role INTO v_caller_role FROM public.users WHERE id = auth.uid();
  
  -- Chỉ cho phép admin
  IF v_caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can approve users';
  END IF;

  -- Cập nhật trạng thái
  UPDATE public.users SET is_approved = true WHERE id = p_user_id::uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Hàm RPC để Admin từ chối/đình chỉ đối tác
CREATE OR REPLACE FUNCTION admin_ban_user(p_user_id TEXT) RETURNS VOID AS $$
DECLARE
  v_caller_role TEXT;
BEGIN
  -- Lấy role của người gọi
  SELECT role INTO v_caller_role FROM public.users WHERE id = auth.uid();
  
  -- Chỉ cho phép admin
  IF v_caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can ban users';
  END IF;

  -- Cập nhật trạng thái
  UPDATE public.users SET is_approved = false WHERE id = p_user_id::uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- SQL Patch 2: Wallet Transactions & RPCs

-- 1. Function: top_up_wallet
CREATE OR REPLACE FUNCTION top_up_wallet(
  p_user_id TEXT,
  p_amount NUMERIC,
  p_description TEXT
) RETURNS VOID AS $$
BEGIN
  -- Update the user's balance
  UPDATE public.users
  SET wallet_balance = COALESCE(wallet_balance, 0) + p_amount
  WHERE id = p_user_id;

  -- Insert a transaction record
  INSERT INTO public.transactions (user_id, amount, type, description, created_at)
  VALUES (p_user_id, p_amount, 'top_up', p_description, now());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. Function: deduct_wallet_balance
CREATE OR REPLACE FUNCTION deduct_wallet_balance(
  p_user_id TEXT,
  p_amount NUMERIC,
  p_description TEXT,
  p_type TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  current_balance NUMERIC;
BEGIN
  -- Lock the row to prevent race conditions during read/write
  SELECT wallet_balance INTO current_balance
  FROM public.users
  WHERE id = p_user_id
  FOR UPDATE;

  -- Verify sufficient funds
  IF current_balance IS NULL OR current_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient wallet balance';
    -- Alternatively you can return false and handle it in Dart, but RAISE stops the transaction entirely
  END IF;

  -- Update balance
  UPDATE public.users
  SET wallet_balance = wallet_balance - p_amount
  WHERE id = p_user_id;

  -- Insert transaction record
  INSERT INTO public.transactions (user_id, amount, type, description, created_at)
  VALUES (p_user_id, -p_amount, p_type, p_description, now());

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. Function: transfer_money
CREATE OR REPLACE FUNCTION transfer_money(
  p_sender_id TEXT,
  p_receiver_id TEXT,
  p_amount NUMERIC,
  p_note TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  sender_balance NUMERIC;
  sender_name TEXT;
BEGIN
  -- Verify amount
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid transfer amount';
  END IF;

  -- Lock the sender row
  SELECT wallet_balance, name INTO sender_balance, sender_name
  FROM public.users
  WHERE id = p_sender_id
  FOR UPDATE;

  -- Check sender balance
  IF sender_balance IS NULL OR sender_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance to transfer';
  END IF;

  -- Deduct from sender
  UPDATE public.users
  SET wallet_balance = wallet_balance - p_amount
  WHERE id = p_sender_id;

  -- Add to receiver (Lock happens automatically on UPDATE, but keeping strict ordering prevents deadlocks)
  UPDATE public.users
  SET wallet_balance = COALESCE(wallet_balance, 0) + p_amount
  WHERE id = p_receiver_id;

  -- Record Sender Transaction
  INSERT INTO public.transactions (user_id, amount, type, description, created_at)
  VALUES (p_sender_id, -p_amount, 'transfer_out', 'Chuyển tiền: ' || COALESCE(p_note, ''), now());

  -- Record Receiver Transaction
  INSERT INTO public.transactions (user_id, amount, type, description, created_at)
  VALUES (p_receiver_id, p_amount, 'transfer_in', 'Nhận tiền từ ' || COALESCE(sender_name, 'Một người bạn') || ': ' || COALESCE(p_note, ''), now());

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

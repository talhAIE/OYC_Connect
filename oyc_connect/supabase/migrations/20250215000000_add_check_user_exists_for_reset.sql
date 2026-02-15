-- RPC used by request-password-reset Edge Function to verify email is registered.
-- Only service_role can call this (not exposed to anon).
CREATE OR REPLACE FUNCTION public.auth_user_exists_by_email(check_email text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM auth.users WHERE email = check_email LIMIT 1);
END;
$$;

GRANT EXECUTE ON FUNCTION public.auth_user_exists_by_email(text) TO service_role;

COMMENT ON FUNCTION public.auth_user_exists_by_email(text) IS 'Returns true if an auth user exists with the given email. Used by request-password-reset Edge Function only.';

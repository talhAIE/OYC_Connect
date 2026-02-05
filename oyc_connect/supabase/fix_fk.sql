-- Fix Foreign Key for Payments to join with Profiles
ALTER TABLE public.payments
DROP CONSTRAINT payments_user_id_fkey;

ALTER TABLE public.payments
ADD CONSTRAINT payments_user_id_fkey
FOREIGN KEY (user_id) REFERENCES public.profiles(id);

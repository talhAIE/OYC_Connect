-- Trigger for notifying admins on new donation
CREATE OR REPLACE FUNCTION public.handle_new_donation()
RETURNS trigger AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://ghrwefeyeyolszbgeqvc.supabase.co/functions/v1/notify-admins',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('request.headers')::json->>'authorization' || '"}'::jsonb,
      body := jsonb_build_object('record', to_jsonb(NEW))
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_donation
AFTER INSERT ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_donation();

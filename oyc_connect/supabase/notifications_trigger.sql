-- Optional legacy integration; NOT installed by notification hardening.
-- Only server-verified payment writes may notify admins. Client payment-history
-- inserts are not authoritative. Configure the Vault server credential and
-- deploy the guarded notify-admins endpoint before enabling this trigger.
create or replace function public.handle_new_donation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare server_key text;
begin
  if coalesce(current_setting('role', true), 'none') in ('anon', 'authenticated') then
    return new;
  end if;
  if new.status is distinct from 'succeeded' then return new; end if;
  select decrypted_secret into server_key from vault.decrypted_secrets
    where name = 'oyc_notification_service_role_key';
  if server_key is null then raise exception 'Notification server credential is missing'; end if;
  perform net.http_post(
    url := 'https://jbjtrppxzbgwbqzcpcib.supabase.co/functions/v1/notify-admins',
    headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer ' || server_key),
    body := jsonb_build_object('record', to_jsonb(new))
  );
  return new;
end;
$$;
revoke all on function public.handle_new_donation() from public, anon, authenticated, service_role;

drop trigger if exists on_new_donation on public.payments;
create trigger on_new_donation after insert on public.payments
  for each row execute function public.handle_new_donation();

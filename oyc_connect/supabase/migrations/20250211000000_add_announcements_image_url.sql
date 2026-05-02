-- Add optional image_url to announcements so admins can attach an image.
ALTER TABLE public.announcements
ADD COLUMN IF NOT EXISTS image_url text;

COMMENT ON COLUMN public.announcements.image_url IS 'Optional image URL (Supabase Storage public URL).';

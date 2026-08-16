CREATE TABLE public.unassigned_rfid_scans (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
  rfid_uid text NOT NULL,
  scanned_at timestamp without time zone DEFAULT now(),
  CONSTRAINT unassigned_rfid_scans_pkey PRIMARY KEY (id),
  CONSTRAINT unassigned_rfid_scans_rfid_uid_key UNIQUE (rfid_uid)
);

ALTER TABLE public.unassigned_rfid_scans ENABLE ROW LEVEL SECURITY;

GRANT ALL ON public.unassigned_rfid_scans TO anon;
GRANT ALL ON public.unassigned_rfid_scans TO authenticated;
GRANT ALL ON public.unassigned_rfid_scans TO service_role;

-- Allow admins to read and delete
CREATE POLICY "Admin full access unassigned_rfids" ON public.unassigned_rfid_scans
  FOR ALL
  USING ( (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin' );

-- Allow IoT devices to insert without authentication
CREATE POLICY "Anon insert unassigned_rfids" ON public.unassigned_rfid_scans
  FOR INSERT
  WITH CHECK (true);

-- Allow public to read if needed for real-time without auth constraints in some edge cases (optional, but admin policy handles it)
CREATE POLICY "Anon read unassigned_rfids" ON public.unassigned_rfid_scans
  FOR SELECT
  USING (true);

-- Enable real-time for the new table
alter publication supabase_realtime add table public.unassigned_rfid_scans;


-- Helper RPC function for IoT device to call
CREATE OR REPLACE FUNCTION public.process_rfid_scan(p_rfid_uid text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_student_id uuid;
    v_user_name text;
BEGIN
    -- Check if user exists
    SELECT id, name INTO v_student_id, v_user_name 
    FROM public.users 
    WHERE rfid_uid = p_rfid_uid 
    LIMIT 1;
    
    IF v_student_id IS NOT NULL THEN
        -- Returning known status. (Attendance logging logic can be handled here if needed)
        RETURN jsonb_build_object(
            'status', 'known', 
            'student_id', v_student_id, 
            'name', v_user_name
        );
    ELSE
        -- Insert into unassigned_rfid_scans (upsert to update timestamp if already exists)
        INSERT INTO public.unassigned_rfid_scans (rfid_uid, scanned_at)
        VALUES (p_rfid_uid, now())
        ON CONFLICT (rfid_uid) 
        DO UPDATE SET scanned_at = now();
        
        RETURN jsonb_build_object(
            'status', 'unknown', 
            'message', 'RFID logged as unassigned'
        );
    END IF;
END;
$$;

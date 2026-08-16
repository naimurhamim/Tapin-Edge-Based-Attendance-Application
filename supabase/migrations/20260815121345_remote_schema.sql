-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

DROP EXTENSION pg_net;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO service_role;

CREATE TABLE public.attendance_logs (
  id              uuid                        DEFAULT extensions.uuid_generate_v4() NOT NULL,
  student_id      uuid,
  subject_id      uuid,
  schedule_id     uuid,
  date            date,
  entry_time      timestamp without time zone,
  exit_time       timestamp without time zone,
  status          text                        DEFAULT 'present'::text,
  attendance_mode text                        DEFAULT 'rfid'::text,
  created_at      timestamp without time zone DEFAULT now()
);

ALTER TABLE public.attendance_logs
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.attendance_logs
  ADD CONSTRAINT attendance_logs_pkey PRIMARY KEY (id);

GRANT ALL ON public.attendance_logs TO anon;

GRANT ALL ON public.attendance_logs TO authenticated;

GRANT ALL ON public.attendance_logs TO service_role;

CREATE POLICY "Insert attendance" ON public.attendance_logs
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Students view own attendance" ON public.attendance_logs
  FOR SELECT
  USING ((auth.uid() = student_id));

CREATE POLICY "Update attendance" ON public.attendance_logs
  FOR UPDATE
  USING (true);

CREATE TABLE public.class_schedules (
  id         uuid                        DEFAULT extensions.uuid_generate_v4() NOT NULL,
  subject_id uuid,
  department text                        NOT NULL,
  section    text                        NOT NULL,
  day_name   text                        NOT NULL,
  start_time time without time zone      NOT NULL,
  end_time   time without time zone      NOT NULL,
  lab_group  text                        DEFAULT 'all'::text,
  is_active  boolean                     DEFAULT true,
  created_at timestamp without time zone DEFAULT now()
);

ALTER TABLE public.class_schedules
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.class_schedules
  ADD CONSTRAINT class_schedules_pkey PRIMARY KEY (id);

ALTER TABLE public.attendance_logs
  ADD CONSTRAINT attendance_logs_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.class_schedules(id);

GRANT ALL ON public.class_schedules TO anon;

GRANT ALL ON public.class_schedules TO authenticated;

GRANT ALL ON public.class_schedules TO service_role;

CREATE POLICY "Anyone can view schedules" ON public.class_schedules
  FOR SELECT
  USING (true);

CREATE TABLE public.holidays (
  id           uuid                        DEFAULT extensions.uuid_generate_v4() NOT NULL,
  holiday_date date                        NOT NULL,
  title        text,
  created_at   timestamp without time zone DEFAULT now()
);

ALTER TABLE public.holidays
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.holidays
  ADD CONSTRAINT holidays_holiday_date_key UNIQUE (holiday_date);

ALTER TABLE public.holidays
  ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);

GRANT ALL ON public.holidays TO anon;

GRANT ALL ON public.holidays TO authenticated;

GRANT ALL ON public.holidays TO service_role;

CREATE POLICY "Anyone can view holidays" ON public.holidays
  FOR SELECT
  USING (true);

CREATE TABLE public.leave_applications (
  id          uuid                        DEFAULT extensions.uuid_generate_v4() NOT NULL,
  student_id  uuid,
  subject_id  uuid,
  schedule_id uuid,
  leave_date  date                        NOT NULL,
  reason      text                        NOT NULL,
  leave_type  text                        DEFAULT 'general'::text,
  status      text                        DEFAULT 'pending'::text,
  admin_note  text,
  created_at  timestamp without time zone DEFAULT now()
);

ALTER TABLE public.leave_applications
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.leave_applications
  ADD CONSTRAINT leave_applications_pkey PRIMARY KEY (id);

ALTER TABLE public.leave_applications
  ADD CONSTRAINT leave_applications_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.class_schedules(id);

GRANT ALL ON public.leave_applications TO anon;

GRANT ALL ON public.leave_applications TO authenticated;

GRANT ALL ON public.leave_applications TO service_role;

CREATE POLICY "Students insert own leaves" ON public.leave_applications
  FOR INSERT
  WITH CHECK ((auth.uid() = student_id));

CREATE POLICY "Students view own leaves" ON public.leave_applications
  FOR SELECT
  USING ((auth.uid() = student_id));

CREATE TABLE public.subjects (
  id         uuid                        DEFAULT extensions.uuid_generate_v4() NOT NULL,
  name       text                        NOT NULL,
  code       text                        NOT NULL,
  department text,
  section    text,
  semester   text,
  created_at timestamp without time zone DEFAULT now()
);

ALTER TABLE public.subjects
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.subjects
  ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);

ALTER TABLE public.attendance_logs
  ADD CONSTRAINT attendance_logs_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);

ALTER TABLE public.class_schedules
  ADD CONSTRAINT class_schedules_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;

ALTER TABLE public.leave_applications
  ADD CONSTRAINT leave_applications_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);

GRANT ALL ON public.subjects TO anon;

GRANT ALL ON public.subjects TO authenticated;

GRANT ALL ON public.subjects TO service_role;

CREATE POLICY "Anyone can view subjects" ON public.subjects
  FOR SELECT
  USING (true);

CREATE TABLE public.users (
  id               uuid                        NOT NULL,
  name             text                        NOT NULL,
  university_id    text                        NOT NULL,
  email            text                        NOT NULL,
  role             text                        DEFAULT 'student'::text,
  department       text,
  section          text,
  lab_group        text,
  phone_number     text,
  rfid_uid         text,
  avatar_url       text,
  telegram_chat_id text,
  created_at       timestamp without time zone DEFAULT now()
);

CREATE POLICY "Admin view all attendance" ON public.attendance_logs
  FOR SELECT
  USING ((( SELECT users.role
   FROM public.users
  WHERE (users.id = auth.uid())) = 'admin'::text));

CREATE POLICY "Admin can manage schedules" ON public.class_schedules
  USING ((( SELECT users.role
   FROM public.users
  WHERE (users.id = auth.uid())) = 'admin'::text));

CREATE POLICY "Admin can manage holidays" ON public.holidays
  USING ((( SELECT users.role
   FROM public.users
  WHERE (users.id = auth.uid())) = 'admin'::text));

CREATE POLICY "Admin update leaves" ON public.leave_applications
  FOR UPDATE
  USING ((( SELECT users.role
   FROM public.users
  WHERE (users.id = auth.uid())) = 'admin'::text));

CREATE POLICY "Admin view all leaves" ON public.leave_applications
  FOR SELECT
  USING ((( SELECT users.role
   FROM public.users
  WHERE (users.id = auth.uid())) = 'admin'::text));

CREATE POLICY "Admin can manage subjects" ON public.subjects
  USING ((( SELECT users.role
   FROM public.users
  WHERE (users.id = auth.uid())) = 'admin'::text));

ALTER TABLE public.users
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.users
  ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.users
  ADD CONSTRAINT users_pkey PRIMARY KEY (id);

ALTER TABLE public.attendance_logs
  ADD CONSTRAINT attendance_logs_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.leave_applications
  ADD CONSTRAINT leave_applications_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.users
  ADD CONSTRAINT users_rfid_uid_key UNIQUE (rfid_uid);

ALTER TABLE public.users
  ADD CONSTRAINT users_university_id_key UNIQUE (university_id);

GRANT ALL ON public.users TO anon;

GRANT ALL ON public.users TO authenticated;

GRANT ALL ON public.users TO service_role;

CREATE POLICY "Admin can update all users" ON public.users
  FOR UPDATE
  USING ((( SELECT users_1.role
   FROM public.users users_1
  WHERE (users_1.id = auth.uid())) = 'admin'::text));

CREATE POLICY "Public can read users" ON public.users
  FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own data" ON public.users
  FOR INSERT
  WITH CHECK ((auth.uid() = id));

CREATE POLICY "Users can update own data" ON public.users
  FOR UPDATE
  USING ((auth.uid() = id));

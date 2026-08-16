CREATE TABLE public.departments (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  created_at timestamp without time zone DEFAULT now()
);

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view departments" ON public.departments
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage departments" ON public.departments
  USING (((SELECT users.role FROM public.users WHERE (users.id = auth.uid())) = 'admin'::text));

CREATE TABLE public.sessions (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  department_id uuid NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  UNIQUE(department_id, name)
);

ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view sessions" ON public.sessions
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage sessions" ON public.sessions
  USING (((SELECT users.role FROM public.users WHERE (users.id = auth.uid())) = 'admin'::text));

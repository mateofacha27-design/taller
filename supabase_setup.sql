

-- 1. Asegurar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Estructura de Salones (si no la tienes creada aún)
CREATE TABLE IF NOT EXISTS public.salones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL
);

-- 3. Estructura de Equipos (si no la tienes creada aún)
CREATE TABLE IF NOT EXISTS public.equipos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT NOT NULL,
  estado BOOLEAN DEFAULT true, -- true = OPERATIVO (BIEN), false = FALLA (MAL)
  observacion TEXT,
  salon_id UUID REFERENCES public.salones(id) ON DELETE CASCADE
);

-- 4. Tabla de Perfiles (para complementar Login y Registro)
CREATE TABLE IF NOT EXISTS public.perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  rol TEXT DEFAULT 'aprendiz', -- 'instructor' o 'aprendiz'
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Trigger automático para crear perfil cuando un usuario se registra en la App
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre, rol)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'nombre', 'Usuario'),
    COALESCE(new.raw_user_meta_data->>'rol', 'aprendiz')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'equipos'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE equipos;
  END IF;
END $$;

-- 7. Configuración de Row Level Security (RLS)
ALTER TABLE public.salones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para desarrollo y pruebas
DROP POLICY IF EXISTS "Lectura publica salones" ON public.salones;
CREATE POLICY "Lectura publica salones" ON public.salones FOR SELECT USING (true);

DROP POLICY IF EXISTS "Lectura publica equipos" ON public.equipos;
CREATE POLICY "Lectura publica equipos" ON public.equipos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir actualizar equipos" ON public.equipos;
CREATE POLICY "Permitir actualizar equipos" ON public.equipos FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir insertar equipos" ON public.equipos;
CREATE POLICY "Permitir insertar equipos" ON public.equipos FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Lectura perfiles" ON public.perfiles;
CREATE POLICY "Lectura perfiles" ON public.perfiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Actualizar propio perfil" ON public.perfiles;
CREATE POLICY "Actualizar propio perfil" ON public.perfiles FOR UPDATE USING (auth.uid() = id);

-- 8. PRECARGA AUTOMÁTICA: Salón 317 y los 30 Computadores
-- Inserta automáticamente los 30 PCs con el formato exacto de la guía (PC-317-01 al 30)
DO $$
DECLARE
  v_salon_id UUID;
  i INT;
BEGIN
  -- Buscar o crear Salón 317
  SELECT id INTO v_salon_id FROM public.salones WHERE nombre = 'Salón 317' LIMIT 1;
  IF v_salon_id IS NULL THEN
    INSERT INTO public.salones (nombre) VALUES ('Salón 317') RETURNING id INTO v_salon_id;
  END IF;

  -- Insertar los 30 puestos si no existen
  FOR i IN 1..30 LOOP
    INSERT INTO public.equipos (codigo, estado, observacion, salon_id)
    SELECT
      'PC-317-' || LPAD(i::text, 2, '0'),
      CASE WHEN i IN (2, 7, 14, 23) THEN false ELSE true END,
      CASE 
        WHEN i = 2 THEN 'Sin señal de video'
        WHEN i = 7 THEN 'Falla teclado / tecla espaciadora'
        WHEN i = 14 THEN 'No enciende'
        WHEN i = 23 THEN 'Problema con puerto de red'
        ELSE 'Core i7 · 16GB · OK'
      END,
      v_salon_id
    WHERE NOT EXISTS (
      SELECT 1 FROM public.equipos WHERE codigo = 'PC-317-' || LPAD(i::text, 2, '0')
    );
  END LOOP;
END $$;

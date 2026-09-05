-- ============================================================
-- RESUME BRAIN - SUPABASE CLOUD BACKUP SCHEMA & RLS POLICIES
-- ============================================================

-- 1. Create Resumes Table
CREATE TABLE IF NOT EXISTS public.resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    resume_id TEXT NOT NULL,
    encrypted_payload JSONB NOT NULL,
    encryption_version INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_resume_id UNIQUE (user_id, resume_id)
);

-- 2. Create Index on user_id and resume_id for Fast Queries
CREATE INDEX IF NOT EXISTS idx_resumes_user_id ON public.resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resumes_resume_id ON public.resumes(resume_id);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies: Ensure users can ONLY access their own records
CREATE POLICY "Users can select own resumes" 
    ON public.resumes 
    FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own resumes" 
    ON public.resumes 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own resumes" 
    ON public.resumes 
    FOR UPDATE 
    USING (auth.uid() = user_id) 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own resumes" 
    ON public.resumes 
    FOR DELETE 
    USING (auth.uid() = user_id);

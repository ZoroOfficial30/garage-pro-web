-- ==============================================================================
-- Migration: Add Stock Items (Inventory) and Employees tables with RLS
-- Project: Garage Accounting Pro (dnrnfvleqkttwiwanyts)
-- ==============================================================================

-- 1. Create stock_items table
CREATE TABLE IF NOT EXISTS public.stock_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    brand TEXT DEFAULT '',
    sku TEXT DEFAULT '',
    quantity INTEGER DEFAULT 0,
    reorder_threshold INTEGER DEFAULT 5,
    cost_price NUMERIC(12, 2) DEFAULT 0.0,
    selling_price NUMERIC(12, 2) DEFAULT 0.0,
    unit TEXT DEFAULT 'Pcs',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) for stock_items
ALTER TABLE public.stock_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view their own stock items" ON public.stock_items;
DROP POLICY IF EXISTS "Users can insert their own stock items" ON public.stock_items;
DROP POLICY IF EXISTS "Users can update their own stock items" ON public.stock_items;
DROP POLICY IF EXISTS "Users can delete their own stock items" ON public.stock_items;

-- RLS Policies for stock_items
CREATE POLICY "Users can view their own stock items"
ON public.stock_items FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own stock items"
ON public.stock_items FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own stock items"
ON public.stock_items FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own stock items"
ON public.stock_items FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_stock_items_user_id ON public.stock_items(user_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_sku ON public.stock_items(user_id, sku);


-- 2. Create employees table
CREATE TABLE IF NOT EXISTS public.employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    pin TEXT DEFAULT '0000',
    is_login_enabled BOOLEAN DEFAULT TRUE,
    phone TEXT NOT NULL,
    avatar_base64 TEXT,
    monthly_salary NUMERIC(12, 2) DEFAULT 250.0,
    is_salary_paid BOOLEAN DEFAULT FALSE,
    last_salary_paid_date TIMESTAMPTZ,
    is_present BOOLEAN DEFAULT TRUE,
    last_attendance_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) for employees
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view their own employees" ON public.employees;
DROP POLICY IF EXISTS "Users can insert their own employees" ON public.employees;
DROP POLICY IF EXISTS "Users can update their own employees" ON public.employees;
DROP POLICY IF EXISTS "Users can delete their own employees" ON public.employees;

-- RLS Policies for employees
CREATE POLICY "Users can view their own employees"
ON public.employees FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own employees"
ON public.employees FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own employees"
ON public.employees FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own employees"
ON public.employees FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON public.employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_phone ON public.employees(user_id, phone);

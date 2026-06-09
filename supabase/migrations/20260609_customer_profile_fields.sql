alter table public.profiles
add column if not exists phone text,
add column if not exists main_address text,
add column if not exists city text,
add column if not exists address_note text;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
      and policyname = 'Users can update own profile'
  ) then
    execute '
      create policy "Users can update own profile"
      on public.profiles
      for update
      to authenticated
      using (auth.uid() = id)
      with check (auth.uid() = id)
    ';
  end if;
end
$$;

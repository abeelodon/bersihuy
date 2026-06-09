alter table public.tasks
add column if not exists before_photo_url text,
add column if not exists after_photo_url text,
add column if not exists proof_uploaded_at timestamptz;

alter table public.profiles
add column if not exists phone text,
add column if not exists service_area text,
add column if not exists base_location text,
add column if not exists work_schedule text;

insert into storage.buckets (id, name, public, file_size_limit)
values ('task-proofs', 'task-proofs', true, 10485760)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit;

drop policy if exists "Task proof images are publicly readable" on storage.objects;
create policy "Task proof images are publicly readable"
on storage.objects for select
using (bucket_id = 'task-proofs');

drop policy if exists "Assigned staff can upload task proofs" on storage.objects;
create policy "Assigned staff can upload task proofs"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'task-proofs'
  and exists (
    select 1
    from public.tasks
    where tasks.id::text = (storage.foldername(name))[1]
      and tasks.staff_id = auth.uid()
  )
);

drop policy if exists "Assigned staff can update task proofs" on storage.objects;
create policy "Assigned staff can update task proofs"
on storage.objects for update
to authenticated
using (
  bucket_id = 'task-proofs'
  and exists (
    select 1
    from public.tasks
    where tasks.id::text = (storage.foldername(name))[1]
      and tasks.staff_id = auth.uid()
  )
)
with check (
  bucket_id = 'task-proofs'
  and exists (
    select 1
    from public.tasks
    where tasks.id::text = (storage.foldername(name))[1]
      and tasks.staff_id = auth.uid()
  )
);

drop policy if exists "Assigned staff can delete task proofs" on storage.objects;
create policy "Assigned staff can delete task proofs"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'task-proofs'
  and exists (
    select 1
    from public.tasks
    where tasks.id::text = (storage.foldername(name))[1]
      and tasks.staff_id = auth.uid()
  )
);

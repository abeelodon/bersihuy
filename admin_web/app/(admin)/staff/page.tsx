"use client";

import { useState } from "react";
import { ClipboardCheck, UserCheck, Users, UsersRound } from "lucide-react";

import { useAdmin } from "@/components/layout/AdminContext";
import { StaffCard } from "@/components/staff/StaffCard";
import { StaffDetailModal } from "@/components/staff/StaffDetailModal";
import { EmptyState } from "@/components/ui/EmptyState";
import { StatCard } from "@/components/ui/StatCard";
import type { AdminStaffProfile } from "@/types/admin";

export default function StaffPage() {
  const { data, query } = useAdmin();
  const [selected, setSelected] = useState<AdminStaffProfile | null>(null);
  const staff = data.staff.filter((person) =>
    [
      person.fullName,
      person.email,
      person.phone || "",
      person.staffArea || "",
      person.staffShift || "",
    ]
      .join(" ")
      .toLowerCase()
      .includes(query.toLowerCase()),
  );

  return (
    <>
      <section className="grid gap-3 sm:grid-cols-3">
        <StatCard
          label="Total Petugas"
          value={String(data.staff.length)}
          helper="Profil role staff"
          icon={Users}
        />
        <StatCard
          label="Petugas Aktif"
          value={String(data.staff.filter((person) => person.isActive).length)}
          helper="Siap bertugas"
          icon={UserCheck}
          accent="green"
        />
        <StatCard
          label="Tugas Diselesaikan"
          value={String(
            data.staff.reduce((total, person) => total + person.completedTasks, 0),
          )}
          helper="Akumulasi tim"
          icon={ClipboardCheck}
          accent="blue"
        />
      </section>

      {staff.length ? (
        <section className="mt-4 grid gap-3 md:grid-cols-2 2xl:grid-cols-3">
          {staff.map((person) => (
            <StaffCard
              key={person.id}
              staff={person}
              onDetail={() => setSelected(person)}
            />
          ))}
        </section>
      ) : (
        <div className="mt-4">
          <EmptyState
            icon={UsersRound}
            title="Petugas belum tersedia"
            description="Profil staff belum tersedia atau tidak cocok dengan pencarian."
          />
        </div>
      )}

      <StaffDetailModal staff={selected} onClose={() => setSelected(null)} />
    </>
  );
}

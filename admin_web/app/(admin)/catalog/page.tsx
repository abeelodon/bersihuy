"use client";

import { useMemo, useState } from "react";
import { Boxes, PackageOpen } from "lucide-react";

import { CatalogCard } from "@/components/catalog/CatalogCard";
import { useAdmin } from "@/components/layout/AdminContext";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Modal } from "@/components/ui/Modal";
import { formatRupiah } from "@/lib/utils/format";
import type { AdminProductItem, AdminServiceItem } from "@/types/admin";

type Detail =
  | { kind: "service"; item: AdminServiceItem }
  | { kind: "product"; item: AdminProductItem }
  | null;

export default function CatalogPage() {
  const { data, query } = useAdmin();
  const [tab, setTab] = useState<"services" | "products">("services");
  const [detail, setDetail] = useState<Detail>(null);
  const services = useMemo(
    () =>
      data.services.filter((item) =>
        [item.name, item.category, item.description]
          .join(" ")
          .toLowerCase()
          .includes(query.toLowerCase()),
      ),
    [data.services, query],
  );
  const products = useMemo(
    () =>
      data.products.filter((item) =>
        [item.name, item.description]
          .join(" ")
          .toLowerCase()
          .includes(query.toLowerCase()),
      ),
    [data.products, query],
  );

  return (
    <>
      <div className="mb-4 inline-flex rounded-2xl border border-[#d8e7e4] bg-white p-1.5 shadow-[0_8px_24px_rgba(28,94,88,0.045)]">
        <Button
          variant={tab === "services" ? "secondary" : "ghost"}
          size="sm"
          className={tab === "services" ? "shadow-sm" : ""}
          onClick={() => setTab("services")}
        >
          Layanan
        </Button>
        <Button
          variant={tab === "products" ? "secondary" : "ghost"}
          size="sm"
          className={tab === "products" ? "shadow-sm" : ""}
          onClick={() => setTab("products")}
        >
          Produk / Add-on
        </Button>
      </div>

      {tab === "services" ? (
        services.length ? (
          <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
            {services.map((service) => (
              <CatalogCard
                key={service.id}
                title={service.name}
                category={service.category}
                price={formatRupiah(service.basePrice)}
                meta={`${service.durationMinutes} menit · Rating ${
                  service.rating ? service.rating.toFixed(1) : "-"
                }`}
                imageAssetPath={service.imageAssetPath}
                active={service.isActive}
                onDetail={() => setDetail({ kind: "service", item: service })}
              />
            ))}
          </section>
        ) : (
          <EmptyState
            icon={Boxes}
            title="Layanan belum tersedia"
            description="Data services belum tersedia atau tidak cocok dengan pencarian."
          />
        )
      ) : products.length ? (
        <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {products.map((product) => (
            <CatalogCard
              key={product.id}
              title={product.name}
              category={product.isAddon ? "Add-on" : "Produk"}
              price={formatRupiah(product.price)}
              meta={
                product.isAddon
                  ? "Produk tambahan layanan"
                  : "Produk Bersihuy"
              }
              imageAssetPath={product.imageAssetPath}
              active={product.isActive}
              onDetail={() => setDetail({ kind: "product", item: product })}
            />
          ))}
        </section>
      ) : (
        <EmptyState
          icon={PackageOpen}
          title="Produk belum tersedia"
          description="Data products belum tersedia atau tidak cocok dengan pencarian."
        />
      )}

      <CatalogDetail detail={detail} onClose={() => setDetail(null)} />
    </>
  );
}

function CatalogDetail({
  detail,
  onClose,
}: {
  detail: Detail;
  onClose: () => void;
}) {
  if (!detail) return null;
  const service = detail.kind === "service" ? detail.item : null;
  const product = detail.kind === "product" ? detail.item : null;
  const item = detail.item;

  return (
    <Modal
      open
      onClose={onClose}
      title={item.name}
      subtitle={service ? "Detail layanan" : "Detail produk / add-on"}
    >
      <div className="mb-5 flex flex-wrap gap-2">
        <Badge tone={item.isActive ? "green" : "neutral"}>
          {item.isActive ? "Aktif" : "Nonaktif"}
        </Badge>
        <Badge tone="neutral">
          {service ? service.category : product?.isAddon ? "Add-on" : "Produk"}
        </Badge>
      </div>
      <div className="space-y-4">
        <Info
          label="Harga"
          value={formatRupiah(service?.basePrice ?? product?.price ?? 0)}
        />
        {service ? (
          <>
            <Info label="Durasi" value={`${service.durationMinutes} menit`} />
            <Info
              label="Rating"
              value={service.rating ? service.rating.toFixed(1) : "-"}
            />
          </>
        ) : null}
        <Info
          label="Deskripsi"
          value={item.description || "Belum ada deskripsi."}
        />
      </div>
    </Modal>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-[#e0ebe9] bg-[#f8fbfa] p-3.5">
      <p className="text-[10px] uppercase tracking-[0.1em] text-[#8a979f]">
        {label}
      </p>
      <p className="mt-1.5 text-xs font-bold leading-6 text-[#253542]">{value}</p>
    </div>
  );
}

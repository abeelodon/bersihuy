export function normalizeAssetPath(path: string | null | undefined) {
  if (!path) return null;

  const trimmed = path.trim().replace(/\\/g, "/");
  if (!trimmed) return null;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  if (trimmed.startsWith("/")) return trimmed;
  if (trimmed.startsWith("assets/")) return `/${trimmed}`;

  return `/assets/images/${trimmed.replace(/^images\//, "")}`;
}

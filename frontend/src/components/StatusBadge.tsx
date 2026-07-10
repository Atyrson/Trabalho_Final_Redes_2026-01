export function StatusBadge({ status }: { status: string }) {
  const label = status === "active" ? "Ativo" : status;
  const className = status === "active" ? "badge badge-ok" : "badge badge-muted";
  return <span className={className}>{label}</span>;
}

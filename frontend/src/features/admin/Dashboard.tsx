import type { AdminDashboard } from "../../api/types";

export function Dashboard({ data }: { data: AdminDashboard }) {
  return (
    <section className="grid gap-4 lg:grid-cols-4">
      <Metric label="Usuarios ativos" value={data.active_users} />
      <Metric label="Canais ativos" value={data.active_channels.join(", ") || "-"} />
      <Metric label="Canal WAN" value={data.wan_active_channel ?? "-"} />
      <Metric label="PIDs VLC" value={data.vlc_pids.length} />
    </section>
  );
}

function Metric({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="card">
      <p className="text-sm text-slate-500">{label}</p>
      <p className="mt-2 text-2xl font-semibold">{value}</p>
    </div>
  );
}

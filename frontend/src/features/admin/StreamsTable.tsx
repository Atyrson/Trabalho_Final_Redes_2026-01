import type { ActiveStream } from "../../api/types";
import { EmptyState } from "../../components/EmptyState";

export function StreamsTable({ streams }: { streams: ActiveStream[] }) {
  if (streams.length === 0) {
    return <EmptyState title="Nenhum stream ativo" />;
  }

  return (
    <div className="overflow-x-auto rounded border border-line bg-white">
      <table className="table">
        <thead>
          <tr>
            <th>Canal</th>
            <th>Perfil</th>
            <th>Multicast</th>
            <th>PID</th>
          </tr>
        </thead>
        <tbody>
          {streams.map((stream) => (
            <tr key={stream.id}>
              <td>
                {stream.channel_number} - {stream.channel_name}
              </td>
              <td>{stream.profile}</td>
              <td className="font-mono">
                {stream.multicast_address}:{stream.port}
              </td>
              <td>{stream.pid}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

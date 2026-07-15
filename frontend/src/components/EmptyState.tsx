export function EmptyState({ title, detail }: { title: string; detail?: string }) {
  return (
    <div className="rounded border border-dashed border-line bg-white px-6 py-10 text-center">
      <h2 className="text-base font-semibold">{title}</h2>
      {detail ? <p className="mt-2 text-sm text-slate-600">{detail}</p> : null}
    </div>
  );
}

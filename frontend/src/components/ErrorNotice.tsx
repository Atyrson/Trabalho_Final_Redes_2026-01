import { AlertTriangle } from "lucide-react";

export function ErrorNotice({ message }: { message: string }) {
  return (
    <div className="notice error">
      <AlertTriangle className="h-5 w-5" aria-hidden="true" />
      <span>{message}</span>
    </div>
  );
}

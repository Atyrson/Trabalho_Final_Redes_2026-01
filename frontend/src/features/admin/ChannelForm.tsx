import { zodResolver } from "@hookform/resolvers/zod";
import { Save } from "lucide-react";
import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import type { ChannelDetail, ChannelPayload, Video } from "../../api/types";

const schema = z.object({
  number: z.coerce.number().int().positive(),
  name: z.string().min(1),
  description: z.string().optional(),
  status: z.string().min(1),
  current_video_id: z.coerce.number().int().positive().optional().or(z.literal("").transform(() => undefined)),
});

type FormValues = z.infer<typeof schema>;

interface ChannelFormProps {
  channel?: ChannelDetail | null;
  videos: Video[];
  isSubmitting: boolean;
  onSubmit: (payload: ChannelPayload) => void;
}

export function ChannelForm({ channel, videos, isSubmitting, onSubmit }: ChannelFormProps) {
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { number: 1, name: "", description: "", status: "active", current_video_id: undefined },
  });

  useEffect(() => {
    form.reset({
      number: channel?.number ?? 1,
      name: channel?.name ?? "",
      description: channel?.description ?? "",
      status: channel?.status ?? "active",
      current_video_id: channel?.current_video_id ?? undefined,
    });
  }, [channel, form]);

  function submit(values: FormValues) {
    onSubmit({
      number: values.number,
      name: values.name,
      description: values.description || null,
      status: values.status,
      current_video_id: values.current_video_id || null,
    });
  }

  return (
    <form className="card space-y-4" onSubmit={form.handleSubmit(submit)}>
      <h2 className="text-lg font-semibold">{channel ? "Editar canal" : "Novo canal"}</h2>
      <div className="grid gap-3 sm:grid-cols-2">
        <div>
          <label className="label">Numero</label>
          <input className="input" type="number" {...form.register("number")} />
        </div>
        <div>
          <label className="label">Status</label>
          <input className="input" {...form.register("status")} />
        </div>
      </div>
      <div>
        <label className="label">Nome</label>
        <input className="input" {...form.register("name")} />
      </div>
      <div>
        <label className="label">Descricao</label>
        <textarea className="input min-h-20 py-2" {...form.register("description")} />
      </div>
      <div>
        <label className="label">Video atual</label>
        <select className="input" {...form.register("current_video_id")}>
          <option value="">Sem video</option>
          {videos.map((video) => (
            <option key={video.id} value={video.id}>
              {video.title}
            </option>
          ))}
        </select>
      </div>
      <button className="button primary" type="submit" disabled={isSubmitting}>
        <Save className="h-4 w-4" aria-hidden="true" />
        Salvar canal
      </button>
    </form>
  );
}

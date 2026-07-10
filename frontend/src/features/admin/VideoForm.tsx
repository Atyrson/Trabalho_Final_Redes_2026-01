import { zodResolver } from "@hookform/resolvers/zod";
import { Save } from "lucide-react";
import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import type { Video, VideoPayload } from "../../api/types";

const schema = z.object({
  title: z.string().min(1),
  hd_path: z.string().min(1),
  ld_path: z.string().min(1),
  description: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

interface VideoFormProps {
  video?: Video | null;
  isSubmitting: boolean;
  onSubmit: (payload: VideoPayload) => void;
}

export function VideoForm({ video, isSubmitting, onSubmit }: VideoFormProps) {
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { title: "", hd_path: "", ld_path: "", description: "" },
  });

  useEffect(() => {
    form.reset({
      title: video?.title ?? "",
      hd_path: video?.hd_path ?? "",
      ld_path: video?.ld_path ?? "",
      description: video?.description ?? "",
    });
  }, [form, video]);

  function submit(values: FormValues) {
    onSubmit({
      title: values.title,
      hd_path: values.hd_path,
      ld_path: values.ld_path,
      description: values.description || null,
      duration_seconds: video?.duration_seconds ?? null,
      bitrate: video?.bitrate ?? null,
      resolution: video?.resolution ?? null,
      video_codec: video?.video_codec ?? null,
      audio_codec: video?.audio_codec ?? null,
    });
  }

  return (
    <form className="card space-y-4" onSubmit={form.handleSubmit(submit)}>
      <h2 className="text-lg font-semibold">{video ? "Editar video" : "Novo video"}</h2>
      <div>
        <label className="label">Titulo</label>
        <input className="input" {...form.register("title")} />
      </div>
      <div>
        <label className="label">Caminho HD</label>
        <input className="input font-mono" {...form.register("hd_path")} />
      </div>
      <div>
        <label className="label">Caminho LD</label>
        <input className="input font-mono" {...form.register("ld_path")} />
      </div>
      <div>
        <label className="label">Descricao</label>
        <textarea className="input min-h-20 py-2" {...form.register("description")} />
      </div>
      <button className="button primary" type="submit" disabled={isSubmitting}>
        <Save className="h-4 w-4" aria-hidden="true" />
        Salvar video
      </button>
    </form>
  );
}

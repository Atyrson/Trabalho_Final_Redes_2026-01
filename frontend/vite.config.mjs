import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const apiBase = env.VITE_API_BASE_URL ?? "/api";
  const target = env.VITE_DEV_API_TARGET ?? "http://127.0.0.1:8000";

  return {
    plugins: [react()],
    server: {
      proxy: {
        [apiBase]: {
          target,
          changeOrigin: true,
        },
      },
    },
    test: {
      environment: "jsdom",
      globals: true,
      setupFiles: "./src/test/setup.ts",
    },
  };
});

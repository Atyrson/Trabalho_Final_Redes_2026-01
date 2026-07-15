import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#172026",
        panel: "#f7f8fa",
        line: "#d8dee5",
        signal: "#0f766e",
        alert: "#b42318",
      },
      boxShadow: {
        soft: "0 12px 28px rgba(22, 32, 38, 0.08)",
      },
    },
  },
  plugins: [],
} satisfies Config;

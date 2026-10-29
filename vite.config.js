import { defineConfig } from "vite";

export default defineConfig({
  test: { include: ["tests/**/*_test.res.js"] },
});

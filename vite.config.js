import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    // During `npm run dev`, online rooms are served by `npm run dev:worker`
    // (wrangler dev on :8787); solo play needs neither.
    proxy: {
      '/api': { target: 'http://localhost:8787', ws: true },
    },
  },
  test: {
    environment: 'happy-dom',
  },
});

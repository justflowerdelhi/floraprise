import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [tailwindcss(), react()],
  base: '/',
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:5148',
        changeOrigin: true,
      },
    },
  },
}))

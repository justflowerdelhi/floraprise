import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [tailwindcss(), react()],
  base: mode === 'production' ? '/floraprise/' : '/',
  server: {
    proxy: {
      '/api': {
        target: 'https://floritribe.com/florapriseapi',
        changeOrigin: true,
        secure: true,
      },
    },
  },
}))

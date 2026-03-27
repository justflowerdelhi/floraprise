import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [tailwindcss(), react()],
  base: '/',
  build: {
    rollupOptions: {
      output: {
        // Keep initial app chunk smaller by splitting heavy dependency groups.
        manualChunks(id) {
          const isPageModule = (name: string) =>
            new RegExp(`[\\\\/]src[\\\\/]pages[\\\\/]${name}[\\\\/]`).test(id)

          if (isPageModule('pos')) return 'page-pos'
          if (isPageModule('orders')) return 'page-orders'
          if (isPageModule('products')) return 'page-products'
          if (isPageModule('production')) return 'page-production'
          if (isPageModule('events')) return 'page-events'
          if (isPageModule('dashboard') || isPageModule('home')) return 'page-dashboard'

          if (new RegExp(`[\\\\/]src[\\\\/]core[\\\\/]`).test(id)) return 'app-core'
          if (new RegExp(`[\\\\/]src[\\\\/]components[\\\\/]`).test(id)) return 'app-components'
          if (new RegExp(`[\\\\/]src[\\\\/]api[\\\\/]`).test(id)) return 'app-api'
          if (new RegExp(`[\\\\/]src[\\\\/]services[\\\\/]`).test(id)) return 'app-services'
          if (new RegExp(`[\\\\/]src[\\\\/]hooks[\\\\/]`).test(id)) return 'app-hooks'
          if (new RegExp(`[\\\\/]src[\\\\/]utils[\\\\/]`).test(id)) return 'app-utils'

          if (!id.includes('node_modules')) return

          if (
            id.includes('node_modules/react/') ||
            id.includes('node_modules/react-dom/') ||
            id.includes('node_modules/react-router-dom/')
          ) {
            return 'vendor-react'
          }

          if (id.includes('node_modules/@mui/icons-material/')) {
            return 'vendor-mui-icons'
          }

          if (id.includes('node_modules/@mui/') || id.includes('node_modules/@emotion/')) {
            return 'vendor-mui'
          }

          if (id.includes('node_modules/recharts/')) {
            return 'vendor-charts'
          }

          if (
            id.includes('node_modules/react-hook-form/') ||
            id.includes('node_modules/@hookform/resolvers/') ||
            id.includes('node_modules/zod/')
          ) {
            return 'vendor-forms'
          }

          if (
            id.includes('node_modules/react-window/') ||
            id.includes('node_modules/react-virtualized-auto-sizer/')
          ) {
            return 'vendor-virtualization'
          }

          if (
            id.includes('node_modules/axios/') ||
            id.includes('node_modules/dayjs/') ||
            id.includes('node_modules/jwt-decode/') ||
            id.includes('node_modules/qrcode/') ||
            id.includes('node_modules/jsbarcode/') ||
            id.includes('node_modules/html-to-image/')
          ) {
            return 'vendor-utils'
          }
        },
      },
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:5148',
        changeOrigin: true,
      },
    },
  },
}))

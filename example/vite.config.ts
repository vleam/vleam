import { fileURLToPath, URL } from 'node:url'

import { defineConfig, Plugin } from 'vite'
import vue from '@vitejs/plugin-vue'
import VueDevTools from 'vite-plugin-vue-devtools'
import Inspect from 'vite-plugin-inspect'

import { vitePluginVueVleam } from 'vleam'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vitePluginVueVleam(), vue(), VueDevTools()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      '@gleam-build': fileURLToPath(new URL('./build/dev/javascript', import.meta.url))
    }
  }
})

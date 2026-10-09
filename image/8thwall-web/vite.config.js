import {defineConfig} from 'vite'
import basicSsl from '@vitejs/plugin-basic-ssl'
import {readFileSync} from 'node:fs'
const cert = process.env.HTTPS_CERT, key = process.env.HTTPS_KEY
if (!!cert !== !!key) throw Error('Set both HTTPS_CERT and HTTPS_KEY')
const https = cert ? {cert: readFileSync(cert), key: readFileSync(key)} : undefined
export default defineConfig({
  plugins: process.env.HTTPS === '1' && !cert ? [basicSsl()] : [],
  server: {host: '0.0.0.0', port: 5173, strictPort: true, https},
  preview: {host: '0.0.0.0', port: 5173, strictPort: true, https},
})

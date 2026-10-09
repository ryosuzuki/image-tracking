import {defineConfig} from 'vite';
import basicSsl from '@vitejs/plugin-basic-ssl';
export default defineConfig({plugins:[basicSsl()],server:{host:'0.0.0.0',port:18961,strictPort:true,https:{}},build:{outDir:'dist'}});

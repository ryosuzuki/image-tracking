import sharp from 'sharp';import fs from 'node:fs/promises';
await fs.mkdir('public/fixtures',{recursive:true});
for(const id of [7,8])await sharp(`public/markers/dots-${id}.svg`).resize(700,700).png().toFile(`public/markers/dots-${id}.png`);

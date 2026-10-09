import {execFile} from 'node:child_process'
import {promisify} from 'node:util'
import {mkdir} from 'node:fs/promises'
import {resolve} from 'node:path'
if(process.platform!=='darwin')throw Error('Native OCR requires macOS Apple Vision; camera tracking works independently')
const directory=resolve('../../work/bin');await mkdir(directory,{recursive:true});await promisify(execFile)('swiftc',[resolve('scripts/vision-ocr.swift'),'-o',resolve(directory,'vision-ocr')],{timeout:60000});console.log('Compiled local Apple Vision OCR; no cloud OCR or API key')

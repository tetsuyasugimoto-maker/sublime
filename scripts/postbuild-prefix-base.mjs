import { promises as fs } from 'fs'
import path from 'path'

const DIST = 'dist'
const BASE = '/sublime'
const PREFIX = (BASE.endsWith('/') ? BASE : BASE + '/')  // "/sublime/"

async function walk(dir) {
  const ents = await fs.readdir(dir, { withFileTypes: true })
  const out = []
  for (const e of ents) {
    const p = path.join(dir, e.name)
    if (e.isDirectory()) out.push(...await walk(p))
    else out.push(p)
  }
  return out
}

function rewriteHtml(s) {
  s = s.replace(/=(["'])\/(?!sublime\/|\/|https?:|data:)/g, (_, q) => `=${q}${PREFIX}`)
  s = s.replace(/srcset=(["'])([^"']+)\1/gi, (m, q, val) => {
    const nv = val.replace(/(^|,\s*)\/(?!sublime\/|\/|https?:|data:)/g, (_m, head) => `${head}${PREFIX}`)
    return `srcset=${q}${nv}${q}`
  })
  return s
}
function rewriteCss(s) {
  return s.replace(/url\(\s*\/(?!sublime\/|\/|https?:|data:)/g, `url(${PREFIX}`)
}

async function main() {
  const files = (await walk(DIST)).filter(f => /\.(html?|css)$/.test(f))
  for (const f of files) {
    const txt = await fs.readFile(f, 'utf8')
    const out = f.endsWith('.css') ? rewriteCss(txt) : rewriteHtml(txt)
    if (out !== txt) {
      await fs.writeFile(f, out, 'utf8')
      console.log('fixed:', f)
    }
  }
  await fs.writeFile(path.join(DIST, '.nojekyll'), '').catch(()=>{})
}
main().catch(e => { console.error(e); process.exit(1) })

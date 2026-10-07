// Renders one or more shots (GLSL scenes) to video files.
// usage: node render/render.mjs <shotId|all> [--still t] [--scale s] [--jobs n]
import { chromium } from 'playwright';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const W = 1920, H = 804, FPS = 24;
const scale = parseFloat(opt('--scale', '1'));
const still = opt('--still', null);
const jobs = parseInt(opt('--jobs', '2'));
const outDir = opt('--out', path.join(ROOT, 'build', 'shots'));
fs.mkdirSync(outDir, { recursive: true });

const shots = JSON.parse(fs.readFileSync(path.join(ROOT, 'shots.json'), 'utf8'));
const lib = fs.readFileSync(path.join(ROOT, 'shaders', 'lib.glsl'), 'utf8');
const post = fs.readFileSync(path.join(ROOT, 'shaders', 'post.glsl'), 'utf8');

const sel = args[0] || 'all';
let todo = sel === 'all' ? shots : shots.filter(s => sel.split(',').includes(s.id));
if (!still && !args.includes('--force')) todo = todo.filter(s => !fs.existsSync(path.join(outDir, s.id + '.mp4')));

const page_html = fs.readFileSync(path.join(ROOT, 'render', 'page.html'), 'utf8');

async function renderShot(browser, shot) {
  const w = Math.round(W * scale / 2) * 2, h = Math.round(H * scale / 2) * 2;
  const src = fs.readFileSync(path.join(ROOT, 'shaders', shot.shader + '.glsl'), 'utf8');
  const frag = lib + '\n#line 1 1\n' + src;
  const n = Math.round(shot.dur * FPS);
  const outFile = still ? path.join(outDir, `${shot.id}_${still}.png`) : path.join(outDir, shot.id + '.mp4');
  const tmpFile = outFile + '.part.mp4';
  let ff;
  if (still) {
    ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', `${w}x${h}`, '-i', '-', '-vf', 'vflip', '-frames:v', '1', outFile]);
  } else {
    ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', `${w}x${h}`, '-r', String(FPS), '-i', '-',
      '-vf', 'vflip', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '14', '-pix_fmt', 'yuv420p', '-f', 'mp4', tmpFile]);
  }
  ff.stderr.on('data', d => process.stderr.write(d));
  const done = new Promise(r => ff.on('close', r));

  const server = http.createServer((req, res) => {
    if (req.url === '/') { res.writeHead(200, { 'content-type': 'text/html' }); res.end(page_html); return; }
    if (req.url.startsWith('/tex/')) {
      const f = path.join(ROOT, decodeURIComponent(req.url.slice(5)));
      res.writeHead(200, { 'content-type': 'image/png' }); res.end(fs.readFileSync(f)); return;
    }
    if (req.url === '/frame') {
      const chunks = [];
      req.on('data', c => chunks.push(c));
      req.on('end', () => {
        const buf = Buffer.concat(chunks);
        const ok = ff.stdin.write(buf);
        if (ok) res.end('ok'); else ff.stdin.once('drain', () => res.end('ok'));
      });
      return;
    }
    res.writeHead(404); res.end();
  });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const port = server.address().port;
  const page = await browser.newPage();
  page.on('console', m => console.log(`[${shot.id}]`, m.text()));
  page.on('pageerror', e => console.log(`[${shot.id}] ERR`, e.message));
  await page.goto(`http://127.0.0.1:${port}/`);
  const t0 = Date.now();
  const frames = still ? [Math.round(parseFloat(still) * FPS)] : null;
  const result = await page.evaluate(async (cfg) => window.run(cfg), {
    w, h, n, fps: FPS, frag, post, params: shot.params || {}, dur: shot.dur, frames, seed: shot.seed || 0,
    tex: shot.tex || [], fadeIn: shot.fadeIn ?? 0, fadeOut: shot.fadeOut ?? 0, ss: shot.ss || 1, tOffset: shot.tOffset || 0,
  });
  await page.close();
  server.close();
  ff.stdin.end();
  await done;
  if (result !== 'ok') { console.log(`[${shot.id}] FAILED: ${result}`); return; }
  if (!still) fs.renameSync(tmpFile, outFile);
  const secs = (Date.now() - t0) / 1000;
  console.log(`[${shot.id}] ${still ? 'still' : n + ' frames'} in ${secs.toFixed(1)}s (${(secs / (frames ? 1 : n)).toFixed(3)} s/frame)`);
}

const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--disable-gpu-watchdog', '--disable-background-timer-throttling'],
});
const queue = [...todo];
await Promise.all(Array.from({ length: Math.min(jobs, queue.length) }, async () => {
  while (queue.length) {
    const s = queue.shift();
    try { await renderShot(browser, s); } catch (e) { console.log(`[${s.id}] exception`, e.message); }
  }
}));
await browser.close();

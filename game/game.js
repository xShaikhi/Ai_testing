const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// ── Resize canvas to fill screen ──────────────────────────────────────────────
function resize() {
  canvas.width  = window.innerWidth;
  canvas.height = window.innerHeight;
}
window.addEventListener('resize', resize);
resize();

// ── Constants ─────────────────────────────────────────────────────────────────
const GRAVITY       = 0.6;
const JUMP_FORCE    = -14;
const GROUND_HEIGHT = 80;   // px from bottom
const PLAYER_W      = 40;
const PLAYER_H      = 55;
const COIN_R        = 14;
const OBS_W         = 38;
const OBS_MIN_H     = 40;
const OBS_MAX_H     = 90;

// ── State ──────────────────────────────────────────────────────────────────────
let state = 'start';   // 'start' | 'playing' | 'dead'
let score = 0;
let highScore = parseInt(localStorage.getItem('runnerHS') || '0');
let frameCount = 0;

// ── Player ─────────────────────────────────────────────────────────────────────
const player = {
  x: 0, y: 0,
  vy: 0,
  onGround: false,
  jumpsLeft: 2,   // double-jump allowed

  reset() {
    this.x = canvas.width * 0.15;
    this.y = groundY() - PLAYER_H;
    this.vy = 0;
    this.onGround = true;
    this.jumpsLeft = 2;
  },

  jump() {
    if (this.jumpsLeft > 0) {
      this.vy = JUMP_FORCE;
      this.onGround = false;
      this.jumpsLeft--;
    }
  },

  update() {
    this.vy += GRAVITY;
    this.y  += this.vy;
    const gy = groundY() - PLAYER_H;
    if (this.y >= gy) {
      this.y = gy;
      this.vy = 0;
      this.onGround = true;
      this.jumpsLeft = 2;
    }
  },

  draw() {
    const x = this.x, y = this.y;
    // Body
    ctx.fillStyle = '#60a5fa';
    roundRect(x, y + 15, PLAYER_W, PLAYER_H - 15, 6);
    // Head
    ctx.fillStyle = '#fbbf24';
    ctx.beginPath();
    ctx.arc(x + PLAYER_W / 2, y + 12, 16, 0, Math.PI * 2);
    ctx.fill();
    // Eye
    ctx.fillStyle = '#1e293b';
    ctx.beginPath();
    ctx.arc(x + PLAYER_W / 2 + 5, y + 10, 3, 0, Math.PI * 2);
    ctx.fill();
    // Legs (animated)
    const legAnim = Math.sin(frameCount * 0.25) * 8;
    ctx.fillStyle = '#3b82f6';
    roundRect(x + 4,            y + PLAYER_H - 5 + legAnim,  14, 10, 4);
    roundRect(x + PLAYER_W - 18, y + PLAYER_H - 5 - legAnim, 14, 10, 4);
  },

  rect() {
    return { x: this.x + 4, y: this.y, w: PLAYER_W - 8, h: PLAYER_H };
  }
};

// ── Obstacles & Coins ──────────────────────────────────────────────────────────
let obstacles = [];
let coins     = [];
let particles = [];

function groundY() { return canvas.height - GROUND_HEIGHT; }

function gameSpeed() {
  return 5 + Math.floor(score / 200) * 0.5;
}

function spawnObstacle() {
  const h = OBS_MIN_H + Math.random() * (OBS_MAX_H - OBS_MIN_H);
  obstacles.push({
    x: canvas.width + OBS_W,
    y: groundY() - h,
    w: OBS_W,
    h
  });
}

function spawnCoin() {
  const gy = groundY();
  const y  = gy - 60 - Math.random() * 80;
  coins.push({ x: canvas.width + COIN_R, y, r: COIN_R, angle: 0 });
}

// ── Particles ──────────────────────────────────────────────────────────────────
function burst(x, y) {
  for (let i = 0; i < 8; i++) {
    const angle = (i / 8) * Math.PI * 2;
    particles.push({
      x, y,
      vx: Math.cos(angle) * (2 + Math.random() * 3),
      vy: Math.sin(angle) * (2 + Math.random() * 3),
      life: 1,
      color: '#fbbf24'
    });
  }
}

// ── AABB collision ─────────────────────────────────────────────────────────────
function overlaps(a, b) {
  return a.x < b.x + b.w && a.x + a.w > b.x &&
         a.y < b.y + b.h && a.y + a.h > b.y;
}

function circleRect(cx, cy, r, rx, ry, rw, rh) {
  const nearX = Math.max(rx, Math.min(cx, rx + rw));
  const nearY = Math.max(ry, Math.min(cy, ry + rh));
  const dx = cx - nearX, dy = cy - nearY;
  return dx * dx + dy * dy < r * r;
}

// ── Drawing helpers ────────────────────────────────────────────────────────────
function roundRect(x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
  ctx.fill();
}

function drawBackground() {
  // Sky gradient
  const grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
  grad.addColorStop(0, '#0f172a');
  grad.addColorStop(1, '#1e293b');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // Stars (static seed based on frameCount for parallax)
  ctx.fillStyle = 'rgba(255,255,255,0.6)';
  for (let i = 0; i < 40; i++) {
    const sx = ((i * 137 + frameCount * 0.2) % canvas.width);
    const sy = (i * 73) % (canvas.height * 0.6);
    ctx.fillRect(sx, sy, 1.5, 1.5);
  }

  // Ground
  ctx.fillStyle = '#22c55e';
  ctx.fillRect(0, groundY(), canvas.width, GROUND_HEIGHT);
  ctx.fillStyle = '#16a34a';
  ctx.fillRect(0, groundY(), canvas.width, 8);

  // Moving ground lines
  ctx.strokeStyle = 'rgba(0,0,0,0.15)';
  ctx.lineWidth = 2;
  const spacing = 80;
  const offset  = (frameCount * gameSpeed()) % spacing;
  for (let x = -offset; x < canvas.width; x += spacing) {
    ctx.beginPath();
    ctx.moveTo(x, groundY() + 4);
    ctx.lineTo(x + 40, groundY() + 4);
    ctx.stroke();
  }
}

function drawObstacles() {
  obstacles.forEach(o => {
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.3)';
    ctx.fillRect(o.x + 4, groundY() - 4, o.w, 8);
    // Body
    ctx.fillStyle = '#ef4444';
    roundRect(o.x, o.y, o.w, o.h, 6);
    // Highlight
    ctx.fillStyle = 'rgba(255,255,255,0.15)';
    roundRect(o.x + 4, o.y + 4, o.w - 8, 10, 4);
    // Warning stripe
    ctx.fillStyle = '#fca5a5';
    for (let sy = o.y + 20; sy < o.y + o.h - 10; sy += 14) {
      ctx.fillRect(o.x + 6, sy, o.w - 12, 5);
    }
  });
}

function drawCoins() {
  coins.forEach(c => {
    c.angle += 0.05;
    const scaleX = Math.abs(Math.cos(c.angle));

    ctx.save();
    ctx.translate(c.x, c.y);
    ctx.scale(scaleX, 1);
    // Glow
    const glow = ctx.createRadialGradient(0, 0, 2, 0, 0, c.r + 4);
    glow.addColorStop(0, 'rgba(251,191,36,0.6)');
    glow.addColorStop(1, 'rgba(251,191,36,0)');
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(0, 0, c.r + 4, 0, Math.PI * 2);
    ctx.fill();
    // Coin
    ctx.fillStyle = '#fbbf24';
    ctx.beginPath();
    ctx.arc(0, 0, c.r, 0, Math.PI * 2);
    ctx.fill();
    // Inner
    ctx.fillStyle = '#f59e0b';
    ctx.beginPath();
    ctx.arc(0, 0, c.r * 0.6, 0, Math.PI * 2);
    ctx.fill();
    // $ symbol
    ctx.fillStyle = '#92400e';
    ctx.font = `bold ${c.r}px Arial`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('$', 0, 1);
    ctx.restore();
  });
}

function drawParticles() {
  particles.forEach(p => {
    ctx.globalAlpha = p.life;
    ctx.fillStyle   = p.color;
    ctx.beginPath();
    ctx.arc(p.x, p.y, 4 * p.life, 0, Math.PI * 2);
    ctx.fill();
  });
  ctx.globalAlpha = 1;
}

function drawHUD() {
  ctx.fillStyle = 'rgba(255,255,255,0.95)';
  ctx.font      = `bold ${canvas.width * 0.055}px Arial`;
  ctx.textAlign = 'left';
  ctx.fillText(`Score: ${score}`, 16, 40);
  ctx.font      = `${canvas.width * 0.04}px Arial`;
  ctx.fillStyle = '#fbbf24';
  ctx.fillText(`Best: ${highScore}`, 16, 70);
}

function drawStartScreen() {
  // Overlay
  ctx.fillStyle = 'rgba(0,0,0,0.55)';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const cx = canvas.width / 2;
  const cy = canvas.height / 2;

  // Card
  ctx.fillStyle = 'rgba(30,41,59,0.95)';
  roundRect(cx - 150, cy - 140, 300, 280, 20);

  ctx.fillStyle = '#fbbf24';
  ctx.font      = `bold ${canvas.width * 0.09}px Arial`;
  ctx.textAlign = 'center';
  ctx.fillText('🏃 RUNNER', cx, cy - 70);

  ctx.fillStyle = '#94a3b8';
  ctx.font      = `${canvas.width * 0.04}px Arial`;
  ctx.fillText('اجمع الكوينز', cx, cy - 30);
  ctx.fillText('تجنب العوائق', cx, cy);

  ctx.fillStyle = '#60a5fa';
  ctx.font      = `${canvas.width * 0.038}px Arial`;
  ctx.fillText('اضغط للقفز (مرتين = double jump)', cx, cy + 40);

  // Start button
  ctx.fillStyle = '#22c55e';
  roundRect(cx - 100, cy + 70, 200, 55, 14);
  ctx.fillStyle = '#fff';
  ctx.font      = `bold ${canvas.width * 0.055}px Arial`;
  ctx.fillText('ابدأ اللعبة', cx, cy + 105);

  if (highScore > 0) {
    ctx.fillStyle = '#fbbf24';
    ctx.font      = `${canvas.width * 0.038}px Arial`;
    ctx.fillText(`أعلى نتيجة: ${highScore}`, cx, cy + 155);
  }
}

function drawGameOver() {
  ctx.fillStyle = 'rgba(0,0,0,0.65)';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const cx = canvas.width / 2;
  const cy = canvas.height / 2;

  ctx.fillStyle = 'rgba(30,41,59,0.95)';
  roundRect(cx - 150, cy - 150, 300, 300, 20);

  ctx.fillStyle = '#ef4444';
  ctx.font      = `bold ${canvas.width * 0.08}px Arial`;
  ctx.textAlign = 'center';
  ctx.fillText('Game Over!', cx, cy - 90);

  ctx.fillStyle = '#fff';
  ctx.font      = `bold ${canvas.width * 0.06}px Arial`;
  ctx.fillText(`Score: ${score}`, cx, cy - 40);

  if (score >= highScore) {
    ctx.fillStyle = '#fbbf24';
    ctx.font      = `bold ${canvas.width * 0.05}px Arial`;
    ctx.fillText('🏆 أعلى نتيجة!', cx, cy + 5);
  } else {
    ctx.fillStyle = '#94a3b8';
    ctx.font      = `${canvas.width * 0.04}px Arial`;
    ctx.fillText(`Best: ${highScore}`, cx, cy + 5);
  }

  // Retry button
  ctx.fillStyle = '#3b82f6';
  roundRect(cx - 100, cy + 45, 200, 55, 14);
  ctx.fillStyle = '#fff';
  ctx.font      = `bold ${canvas.width * 0.055}px Arial`;
  ctx.fillText('العب مجدداً', cx, cy + 80);

  ctx.fillStyle = '#64748b';
  ctx.font      = `${canvas.width * 0.035}px Arial`;
  ctx.fillText('اضغط في أي مكان', cx, cy + 130);
}

// ── Main update loop ───────────────────────────────────────────────────────────
let lastObstacle = 0;
let lastCoin     = 0;
const OBS_INTERVAL  = 1800;  // ms
const COIN_INTERVAL = 900;

let lastTime = 0;

function update(ts) {
  const dt = ts - lastTime;
  lastTime  = ts;

  if (state !== 'playing') return;

  frameCount++;
  score += 1;

  const spd = gameSpeed();

  // Spawn
  if (ts - lastObstacle > OBS_INTERVAL - score * 0.3) {
    spawnObstacle();
    lastObstacle = ts;
  }
  if (ts - lastCoin > COIN_INTERVAL) {
    spawnCoin();
    lastCoin = ts;
  }

  // Move obstacles
  obstacles.forEach(o => o.x -= spd);
  obstacles = obstacles.filter(o => o.x + o.w > -10);

  // Move coins
  coins.forEach(c => c.x -= spd);
  coins = coins.filter(c => c.x + c.r > -10);

  // Update particles
  particles.forEach(p => {
    p.x   += p.vx;
    p.y   += p.vy;
    p.vy  += 0.1;
    p.life -= 0.04;
  });
  particles = particles.filter(p => p.life > 0);

  // Update player
  player.update();

  const pr = player.rect();

  // Coin collision
  coins = coins.filter(c => {
    if (circleRect(c.x, c.y, c.r, pr.x, pr.y, pr.w, pr.h)) {
      score += 50;
      burst(c.x, c.y);
      return false;
    }
    return true;
  });

  // Obstacle collision
  for (const o of obstacles) {
    if (overlaps(pr, { x: o.x + 3, y: o.y, w: o.w - 6, h: o.h })) {
      die();
      return;
    }
  }
}

function die() {
  state = 'dead';
  if (score > highScore) {
    highScore = score;
    localStorage.setItem('runnerHS', highScore);
  }
}

// ── Draw ───────────────────────────────────────────────────────────────────────
function draw() {
  drawBackground();
  drawObstacles();
  drawCoins();
  drawParticles();
  player.draw();
  if (state === 'playing') drawHUD();
  if (state === 'start')   drawStartScreen();
  if (state === 'dead')    drawGameOver();
}

// ── Game loop ──────────────────────────────────────────────────────────────────
function loop(ts) {
  update(ts);
  draw();
  requestAnimationFrame(loop);
}

// ── Input ──────────────────────────────────────────────────────────────────────
function handleInput() {
  if (state === 'start') {
    startGame();
  } else if (state === 'playing') {
    player.jump();
  } else if (state === 'dead') {
    startGame();
  }
}

canvas.addEventListener('touchstart', e => { e.preventDefault(); handleInput(); }, { passive: false });
canvas.addEventListener('mousedown', handleInput);
document.addEventListener('keydown', e => {
  if (e.code === 'Space' || e.code === 'ArrowUp') {
    e.preventDefault();
    handleInput();
  }
});

// ── Start ──────────────────────────────────────────────────────────────────────
function startGame() {
  obstacles   = [];
  coins       = [];
  particles   = [];
  score       = 0;
  frameCount  = 0;
  lastObstacle = 0;
  lastCoin    = 0;
  player.reset();
  state = 'playing';
}

// Init
requestAnimationFrame(loop);

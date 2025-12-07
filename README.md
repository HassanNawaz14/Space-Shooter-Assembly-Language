<h1 align="center">⭐ <b>Bubble Shooter / Space Shooter — Assembly Language (x86 Real Mode)</b> ⭐</h1>
<p align="center"><i>A complete, real-time text-mode arcade game built entirely in Assembly.</i></p>

<br>

<p align="center">
  <b>🧱 Brick Breaker • 🐍 Snake • 🚀 Space Shooter</b><br>
  <i>This is my third Assembly Language game in the last two months.</i>
</p>

<hr>

<h2>🎮 <b>Project Overview</b></h2>

<p>
This project is a fully playable <b>Space Shooter / Bubble Shooter–style game</b> written in pure <b>x86 Assembly (8086 Real Mode)</b> featuring:
</p>

<ul>
  <li>Direct video memory rendering (<code>0xB800</code>)</li>
  <li>Timer & Keyboard interrupt hooking</li>
  <li>Real-time multitasking using custom ISR scheduling</li>
  <li>Pseudo-random bubble patterns</li>
  <li>Full gameplay loop with UI, scoring, menus & effects</li>
  <li>Text-mode graphics (80×25)</li>
</ul>

<hr>

<h2>🧩 <b>Features at a Glance</b></h2>

<h3>✔️ Gameplay</h3>
<ul>
  <li>Paddle movement using arrow keys</li>
  <li>Bullet firing (Up arrow)</li>
  <li>Falling bubbles with semi-random paths</li>
  <li>Collision detection</li>
  <li>Win & Game Over screens</li>
</ul>

<h3>✔️ UI & Rendering</h3>
<ul>
  <li>Interactive start menu</li>
  <li>Colored bricks/bubbles</li>
  <li>Status bar with score, lives, speed</li>
  <li>Dynamic border rendering</li>
  <li>Optimized partial redraw (no full screen flicker)</li>
</ul>

<h3>✔️ System-Level Programming</h3>
<ul>
  <li>Custom <b>Keyboard ISR</b></li>
  <li>Custom <b>Timer ISR (100 Hz)</b></li>
  <li>3-task scheduler inside ISR</li>
  <li>2000-cell grid simulation</li>
  <li>Lightweight pseudo-random generator</li>
</ul>

<hr>

<h2>🎥 <b>Demo Video</b></h2>

<p>🎬 <b>Gameplay Demo:</b><br>
<a href="#">[Video Link Here]</a></p>

<hr>

<h2>🛠️ <b>Technical Breakdown</b></h2>

<h3>🧵 Multitasking via Custom Timer ISR</h3>

<pre>
mov al, 0x36
out 0x43, al
mov ax, 11932
out 0x40, al
mov al, ah
out 0x40, al
</pre>

<h3>🎯 ISR Tasks</h3>

<ul>
  <li><b>Task 0:</b> MainGameTask</li>
  <li><b>Task 1:</b> BulletTask</li>
  <li><b>Task 2:</b> MoveActiveBubbleTask</li>
</ul>

<h3>🧮 Rendering</h3>
<pre>
mov ax, 0xB800
mov es, ax
mov word [es:di], (color << 8) + character
</pre>

<h3>🔐 Input Handling</h3>

<ul>
  <li>← → : Move paddle</li>
  <li>↑ : Shoot</li>
  <li>ESC : Return to menu</li>
  <li>+ / – : Adjust falling speed</li>
</ul>

<hr>

<h2>📂 <b>Project Structure</b></h2>

<pre>
📁 SpaceShooter/
│── SpaceShooter.asm      # Complete game source
│── README.md             # HTML-based README
│── demo.mp4              # Gameplay demo
│── exp.com  # Compiled executable
</pre>

<hr>

<h2>▶️ <b>How to Run</b></h2>

<h3>Option 1 — DOSBox (Recommended)</h3>
<pre>
mount c path_to_folder
c:
SpaceShooter.com
</pre>

<h3>Option 2 — EMU8086</h3>
<p>Open → Compile → Run</p>

<h3>Option 3 — Real DOS (Bare Metal)</h3>
<p>Copy <code>.COM</code> → Run directly on DOS hardware.</p>

<hr>

<h2>🚀 <b>Future Improvements (Planned for future)</b></h2>

<ul>
  <li>PC Speaker sound effects</li>
  <li>Multiple bubble types</li>
  <li>Power-ups</li>
  <li>High score saving</li>
  <li>Menu animations</li>
</ul>

<hr>

<h2>🤝 <b>Contributing</b></h2>
<p>Feel free to fork the project and submit pull requests!</p>

<hr>

<h2>📜 <b>License</b></h2>
<p>Released under the <b>MIT License</b>. Free to use & modify.</p>

<hr>

<h2>⭐ <b>Support</b></h2>
<p>If you like this project, please star ⭐ the repository!</p>

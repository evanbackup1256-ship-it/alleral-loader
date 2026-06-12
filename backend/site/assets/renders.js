(() => {
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function initHeroMesh() {
    const canvas = document.getElementById("heroMesh");
    if (!canvas || reduced) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let w = 0;
    let h = 0;
    let dpr = 1;
    let t = 0;
    let mx = 0.5;
    let my = 0.4;

    function resize() {
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      const rect = canvas.parentElement?.getBoundingClientRect();
      w = Math.floor((rect?.width || 480) * dpr);
      h = Math.floor((rect?.height || 480) * dpr);
      canvas.width = w;
      canvas.height = h;
      canvas.style.width = `${w / dpr}px`;
      canvas.style.height = `${h / dpr}px`;
    }

    window.addEventListener("mousemove", (e) => {
      const rect = canvas.getBoundingClientRect();
      mx = (e.clientX - rect.left) / rect.width;
      my = (e.clientY - rect.top) / rect.height;
    }, { passive: true });

    function draw() {
      t += 1;
      ctx.clearRect(0, 0, w, h);

      const blobs = [
        { x: 0.35, y: 0.4, r: 0.45, hue: 190 },
        { x: 0.65, y: 0.55, r: 0.38, hue: 265 },
        { x: 0.5, y: 0.25, r: 0.32, hue: 320 },
      ];

      blobs.forEach((b, i) => {
        const ox = Math.sin(t * 0.002 + i * 1.7) * 0.08;
        const oy = Math.cos(t * 0.0016 + i) * 0.07;
        const px = (b.x + ox + (mx - 0.5) * 0.08) * w;
        const py = (b.y + oy + (my - 0.5) * 0.08) * h;
        const rad = b.r * Math.min(w, h);
        const g = ctx.createRadialGradient(px, py, 0, px, py, rad);
        g.addColorStop(0, `hsla(${b.hue}, 95%, 62%, 0.28)`);
        g.addColorStop(0.5, `hsla(${b.hue}, 80%, 50%, 0.08)`);
        g.addColorStop(1, "transparent");
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, w, h);
      });

      requestAnimationFrame(draw);
    }

    resize();
    window.addEventListener("resize", resize, { passive: true });
    requestAnimationFrame(draw);
  }

  function initOrbitParallax() {
    const scene = document.querySelector(".hero-orbit-scene");
    if (!scene || reduced) return;
    let tx = 0;
    let ty = 0;
    let cx = 0;
    let cy = 0;

    scene.addEventListener("mousemove", (e) => {
      const rect = scene.getBoundingClientRect();
      tx = ((e.clientX - rect.left) / rect.width - 0.5) * 24;
      ty = ((e.clientY - rect.top) / rect.height - 0.5) * 18;
    });

    function tick() {
      cx += (tx - cx) * 0.08;
      cy += (ty - cy) * 0.08;
      scene.style.transform = `rotateX(${cy * 0.15}deg) rotateY(${cx * 0.15}deg)`;
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }

  function boot() {
    initHeroMesh();
    initOrbitParallax();
  }

  window.AlleralRenders = { boot };

  window.addEventListener("alleral:gate-passed", boot, { once: true });
  if (!document.body?.classList.contains("cf-gate-active")) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", boot);
    } else {
      boot();
    }
  }
})();

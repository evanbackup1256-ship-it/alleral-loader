(() => {
  const canvas = document.getElementById("bgCanvas");
  if (!canvas) return;

  const ctx = canvas.getContext("2d");
  let w = 0;
  let h = 0;
  let particles = [];
  let mouse = { x: 0.5, y: 0.5 };
  let raf = 0;

  const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function resize() {
    w = canvas.width = window.innerWidth;
    h = canvas.height = window.innerHeight;
    const count = prefersReduced ? 0 : Math.min(80, Math.floor((w * h) / 18000));
    particles = Array.from({ length: count }, () => ({
      x: Math.random() * w,
      y: Math.random() * h,
      r: Math.random() * 1.6 + 0.4,
      vx: (Math.random() - 0.5) * 0.35,
      vy: (Math.random() - 0.5) * 0.35,
      hue: Math.random() > 0.5 ? 18 : 168,
    }));
  }

  function draw() {
    if (!ctx || prefersReduced) return;
    ctx.clearRect(0, 0, w, h);

    const mx = mouse.x * w;
    const my = mouse.y * h;

    for (let i = 0; i < particles.length; i += 1) {
      const p = particles[i];
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0) p.x = w;
      if (p.x > w) p.x = 0;
      if (p.y < 0) p.y = h;
      if (p.y > h) p.y = 0;

      const dx = mx - p.x;
      const dy = my - p.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 140) {
        p.x -= dx * 0.008;
        p.y -= dy * 0.008;
      }

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = `hsla(${p.hue}, 90%, 65%, 0.55)`;
      ctx.fill();

      for (let j = i + 1; j < particles.length; j += 1) {
        const q = particles[j];
        const ddx = p.x - q.x;
        const ddy = p.y - q.y;
        const d = ddx * ddx + ddy * ddy;
        if (d < 9000) {
          ctx.strokeStyle = `hsla(${(p.hue + q.hue) / 2}, 70%, 60%, ${0.12 * (1 - d / 9000)})`;
          ctx.lineWidth = 0.6;
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(q.x, q.y);
          ctx.stroke();
        }
      }
    }

    raf = requestAnimationFrame(draw);
  }

  window.addEventListener("resize", resize);
  window.addEventListener("mousemove", (e) => {
    mouse.x = e.clientX / window.innerWidth;
    mouse.y = e.clientY / window.innerHeight;
  });

  resize();
  if (!prefersReduced) draw();

  window.AlleralEffects = {
    observeReveals(root = document) {
      const items = root.querySelectorAll(".reveal:not(.visible)");
      if (!items.length) return;
      const io = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              entry.target.classList.add("visible");
              io.unobserve(entry.target);
            }
          });
        },
        { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
      );
      items.forEach((el, i) => {
        el.style.transitionDelay = `${Math.min(i * 0.06, 0.36)}s`;
        io.observe(el);
      });
    },

    bindCardTilt(root = document) {
      if (prefersReduced) return;
      root.querySelectorAll(".card[data-tilt]").forEach((card) => {
        card.addEventListener("mousemove", (e) => {
          const rect = card.getBoundingClientRect();
          const x = (e.clientX - rect.left) / rect.width - 0.5;
          const y = (e.clientY - rect.top) / rect.height - 0.5;
          card.style.transform = `perspective(800px) rotateY(${x * 10}deg) rotateX(${-y * 10}deg) translateY(-4px)`;
        });
        card.addEventListener("mouseleave", () => {
          card.style.transform = "";
        });
      });
    },

    stop() {
      if (raf) cancelAnimationFrame(raf);
    },
  };

  window.AlleralEffects.observeReveals();
})();

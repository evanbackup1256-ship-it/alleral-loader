(() => {
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const EASE = (t) => 1 - (1 - t) ** 3;

  function animateNumber(el, target, duration = 1200) {
    if (!el) return;
    const start = parseInt(el.textContent, 10) || 0;
    const diff = target - start;
    if (diff === 0) {
      el.textContent = String(target);
      return;
    }
    const t0 = performance.now();
    function frame(now) {
      const p = Math.min((now - t0) / duration, 1);
      el.textContent = String(Math.round(start + diff * EASE(p)));
      if (p < 1) requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  function initScrollProgress() {
    const bar = document.getElementById("scrollProgress");
    if (!bar || reduced) return;
    let ticking = false;
    window.addEventListener("scroll", () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        const max = document.documentElement.scrollHeight - window.innerHeight;
        const p = max > 0 ? window.scrollY / max : 0;
        bar.style.transform = `scaleX(${p})`;
        ticking = false;
      });
    }, { passive: true });
  }

  function initCursorGlow() {
    const glow = document.getElementById("cursorGlow");
    if (!glow || reduced || window.matchMedia("(pointer: coarse)").matches) return;
    let x = 0;
    let y = 0;
    let tx = 0;
    let ty = 0;
    window.addEventListener("mousemove", (e) => {
      tx = e.clientX;
      ty = e.clientY;
    }, { passive: true });
    function tick() {
      x += (tx - x) * 0.12;
      y += (ty - y) * 0.12;
      glow.style.transform = `translate(${x}px, ${y}px)`;
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }

  function initConstellation() {
    const canvas = document.getElementById("siteCanvas");
    if (!canvas || reduced) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let w = 0;
    let h = 0;
    let dpr = 1;
    let mx = 0.5;
    let my = 0.5;
    const nodes = [];
    const count = 72;

    function resize() {
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      w = Math.floor(window.innerWidth * dpr);
      h = Math.floor(window.innerHeight * dpr);
      canvas.width = w;
      canvas.height = h;
      canvas.style.width = `${w / dpr}px`;
      canvas.style.height = `${h / dpr}px`;
      nodes.length = 0;
      for (let i = 0; i < count; i += 1) {
        nodes.push({
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.35,
          vy: (Math.random() - 0.5) * 0.35,
          r: Math.random() * 1.8 + 0.6,
        });
      }
    }

    window.addEventListener("mousemove", (e) => {
      mx = e.clientX / window.innerWidth;
      my = e.clientY / window.innerHeight;
    }, { passive: true });

    function frame() {
      ctx.clearRect(0, 0, w, h);
      const cx = mx * w;
      const cy = my * h;

      for (const n of nodes) {
        n.x += n.vx;
        n.y += n.vy;
        if (n.x < 0 || n.x > w) n.vx *= -1;
        if (n.y < 0 || n.y > h) n.vy *= -1;

        const dx = n.x - cx;
        const dy = n.y - cy;
        const dist = Math.hypot(dx, dy);
        if (dist < 140 * dpr) {
          n.x += (dx / dist) * 0.8;
          n.y += (dy / dist) * 0.8;
        }
      }

      for (let i = 0; i < nodes.length; i += 1) {
        for (let j = i + 1; j < nodes.length; j += 1) {
          const a = nodes[i];
          const b = nodes[j];
          const d = Math.hypot(a.x - b.x, a.y - b.y);
          if (d > 120 * dpr) continue;
          const alpha = (1 - d / (120 * dpr)) * 0.35;
          ctx.strokeStyle = `rgba(34, 211, 238, ${alpha})`;
          ctx.lineWidth = 0.6 * dpr;
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        }
      }

      for (const n of nodes) {
        ctx.fillStyle = "rgba(167, 139, 250, 0.85)";
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.r * dpr, 0, Math.PI * 2);
        ctx.fill();
      }

      requestAnimationFrame(frame);
    }

    resize();
    window.addEventListener("resize", resize, { passive: true });
    requestAnimationFrame(frame);
  }

  function initNavIndicator() {
    const nav = document.getElementById("mainNav");
    const indicator = document.getElementById("navIndicator");
    if (!nav || !indicator) return;

    function moveTo(link) {
      if (!link) return;
      const navRect = nav.getBoundingClientRect();
      const rect = link.getBoundingClientRect();
      indicator.style.width = `${rect.width}px`;
      indicator.style.transform = `translateX(${rect.left - navRect.left}px)`;
      indicator.style.opacity = "1";
    }

    const links = [...nav.querySelectorAll("a[data-section]")];
    links.forEach((link) => {
      link.addEventListener("mouseenter", () => moveTo(link));
      link.addEventListener("focus", () => moveTo(link));
    });
    nav.addEventListener("mouseleave", () => {
      const active = links.find((a) => a.classList.contains("active")) || links[0];
      moveTo(active);
    });

    const observer = new MutationObserver(() => {
      const active = links.find((a) => a.classList.contains("active")) || links[0];
      moveTo(active);
    });
    links.forEach((l) => observer.observe(l, { attributes: true, attributeFilter: ["class"] }));
    moveTo(links.find((a) => a.classList.contains("active")) || links[0]);
  }

  function initMagneticButtons() {
    if (reduced || window.matchMedia("(pointer: coarse)").matches) return;
    document.querySelectorAll(".btn-magnetic").forEach((btn) => {
      btn.addEventListener("mousemove", (e) => {
        const rect = btn.getBoundingClientRect();
        const x = e.clientX - rect.left - rect.width / 2;
        const y = e.clientY - rect.top - rect.height / 2;
        btn.style.transform = `translate(${x * 0.12}px, ${y * 0.18}px)`;
      });
      btn.addEventListener("mouseleave", () => {
        btn.style.transform = "";
      });
    });
  }

  function splitHeroText() {
    const el = document.querySelector("[data-split]");
    if (!el || reduced) return;
    const text = el.textContent || "";
    el.textContent = "";
    el.classList.add("hero-brand-split");
    [...text].forEach((char, i) => {
      const span = document.createElement("span");
      span.className = "hero-char";
      span.textContent = char;
      span.style.animationDelay = `${0.04 * i}s`;
      el.appendChild(span);
    });
  }

  function initTiltCards() {
    if (reduced || window.matchMedia("(pointer: coarse)").matches) return;
    document.addEventListener("mousemove", (e) => {
      const card = e.target.closest(".game-card, .glass-panel.tilt");
      if (!card) return;
      const rect = card.getBoundingClientRect();
      const px = (e.clientX - rect.left) / rect.width - 0.5;
      const py = (e.clientY - rect.top) / rect.height - 0.5;
      card.style.setProperty("--tilt-x", `${py * -8}deg`);
      card.style.setProperty("--tilt-y", `${px * 8}deg`);
    });
    document.addEventListener("mouseleave", (e) => {
      if (e.target.closest?.(".game-card")) {
        e.target.closest(".game-card").style.removeProperty("--tilt-x");
        e.target.closest(".game-card").style.removeProperty("--tilt-y");
      }
    }, true);
  }

  function observeReveals(root = document) {
    const items = root.querySelectorAll(".reveal:not(.visible)");
    if (!items.length) return;

    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const el = entry.target;
          const delay = parseInt(el.dataset.revealDelay || "0", 10);
          const siblings = el.parentElement?.querySelectorAll(":scope > .reveal:not(.visible)") || [];
          const index = [...siblings].indexOf(el);
          const stagger = index >= 0 ? Math.min(index * 70, 420) : 0;
          setTimeout(() => el.classList.add("visible"), delay + stagger);
          io.unobserve(el);
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -6% 0px" }
    );

    items.forEach((el) => io.observe(el));
  }

  function initHeroSequence() {
    document.querySelectorAll(".hero .reveal").forEach((el, i) => {
      setTimeout(() => el.classList.add("visible"), 80 + i * 90);
    });
  }

  window.AlleralEffects = {
    observeReveals,
    animateCounters() {
      document.querySelectorAll("[data-count]").forEach((el) => {
        animateNumber(el, parseInt(el.dataset.count || el.textContent, 10) || 0);
      });
    },
    bindMotion() {
      initMagneticButtons();
      initTiltCards();
    },
    animateNumber,
    refreshMotion() {
      initMagneticButtons();
    },
  };

  document.addEventListener("toggle", (e) => {
    const item = e.target;
    if (item?.classList?.contains("faq-item")) {
      item.classList.toggle("faq-open", item.open);
    }
  }, true);

  function bootMotion() {
    initScrollProgress();
    initCursorGlow();
    initConstellation();
    initNavIndicator();
    splitHeroText();
    initHeroSequence();
    observeReveals();
    initMagneticButtons();
    initTiltCards();

    const nav = document.getElementById("siteNav");
    if (nav) {
      window.addEventListener("scroll", () => {
        nav.classList.toggle("nav-scrolled", window.scrollY > 20);
      }, { passive: true });
    }
  }

  window.addEventListener("alleral:gate-passed", bootMotion, { once: true });
  if (!document.body?.classList.contains("cf-gate-active")) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootMotion);
    } else {
      bootMotion();
    }
  }
})();

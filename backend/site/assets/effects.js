(() => {
  const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function animateNumber(el, target, duration = 900) {
    if (prefersReduced || !el) {
      if (el) el.textContent = String(target);
      return;
    }
    const start = parseInt(el.textContent, 10) || 0;
    const diff = target - start;
    if (diff === 0) return;
    const t0 = performance.now();
    function frame(now) {
      const p = Math.min((now - t0) / duration, 1);
      const eased = 1 - (1 - p) ** 3;
      el.textContent = String(Math.round(start + diff * eased));
      if (p < 1) requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  function bindTilt(card) {
    if (prefersReduced || card.dataset.tiltBound) return;
    card.dataset.tiltBound = "1";
    card.addEventListener("mousemove", (e) => {
      const r = card.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width - 0.5;
      const y = (e.clientY - r.top) / r.height - 0.5;
      card.style.transform = `perspective(900px) rotateX(${(-y * 6).toFixed(2)}deg) rotateY(${(x * 6).toFixed(2)}deg) translateY(-6px) scale(1.02)`;
    });
    card.addEventListener("mouseleave", () => {
      card.style.transform = "";
    });
  }

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
        { threshold: 0.08, rootMargin: "0px 0px -40px 0px" }
      );
      items.forEach((el, i) => {
        el.style.transitionDelay = `${Math.min(i * 0.05, 0.35)}s`;
        io.observe(el);
      });
    },

    animateCounters() {
      document.querySelectorAll("[data-count]").forEach((el) => {
        const target = parseInt(el.dataset.count || el.textContent, 10) || 0;
        animateNumber(el, target);
      });
    },

    bindMotion(root = document) {
      if (prefersReduced) return;
      root.querySelectorAll(".tilt-card:not([data-tilt-bound])").forEach(bindTilt);
    },

    animateNumber,
  };

  window.AlleralEffects.observeReveals();

  if (!prefersReduced) {
    const aurora = document.querySelector(".aurora");
    window.addEventListener("scroll", () => {
      if (aurora) aurora.style.transform = `translateY(${window.scrollY * 0.12}px)`;
    }, { passive: true });

    window.AlleralEffects.bindMotion();
  }

  const nav = document.getElementById("siteNav") || document.querySelector(".nav-shell");
  if (nav) {
    window.addEventListener("scroll", () => {
      nav.classList.toggle("nav-scrolled", window.scrollY > 12);
    }, { passive: true });
  }

  document.addEventListener("toggle", (e) => {
    const item = e.target;
    if (item?.classList?.contains("faq-item")) {
      item.classList.toggle("faq-open", item.open);
    }
  }, true);
})();

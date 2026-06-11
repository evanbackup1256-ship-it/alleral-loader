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

    animateNumber,
  };

  window.AlleralEffects.observeReveals();

  if (!prefersReduced) {
    const aurora = document.querySelector(".aurora");
    window.addEventListener("scroll", () => {
      if (aurora) aurora.style.transform = `translateY(${window.scrollY * 0.12}px)`;
    }, { passive: true });

    document.querySelectorAll(".btn, .filter-pill, .game-card, .feature-card").forEach((el) => {
      el.addEventListener("mouseenter", () => el.classList.add("motion-hover"));
      el.addEventListener("mouseleave", () => el.classList.remove("motion-hover"));
    });
  }

  const nav = document.getElementById("siteNav") || document.querySelector(".nav-shell");
  if (nav) {
    window.addEventListener("scroll", () => {
      nav.classList.toggle("nav-scrolled", window.scrollY > 12);
    }, { passive: true });
  }

  document.querySelectorAll(".faq-item").forEach((item) => {
    item.addEventListener("toggle", () => {
      if (item.open) {
        item.classList.add("faq-open");
      } else {
        item.classList.remove("faq-open");
      }
    });
  });
})();

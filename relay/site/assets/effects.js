(() => {
  const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

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
        { threshold: 0.08, rootMargin: "0px 0px -60px 0px" }
      );
      items.forEach((el, i) => {
        el.style.transitionDelay = `${Math.min(i * 0.05, 0.3)}s`;
        io.observe(el);
      });
    },
  };

  window.AlleralEffects.observeReveals();

  if (!prefersReduced) {
    const aurora = document.querySelector(".aurora");
    window.addEventListener("scroll", () => {
      if (!aurora) return;
      const y = window.scrollY * 0.15;
      aurora.style.transform = `translateY(${y}px)`;
    }, { passive: true });
  }
})();

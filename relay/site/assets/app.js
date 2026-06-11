(() => {
  const GRADIENTS = [
    "linear-gradient(135deg, #1a3a5c 0%, #0a1628 50%, #2997ff33 100%)",
    "linear-gradient(135deg, #2d1f4e 0%, #0f0a1a 50%, #bf5af233 100%)",
    "linear-gradient(135deg, #1a3d2e 0%, #0a1a12 50%, #30d15833 100%)",
    "linear-gradient(135deg, #3d2a1a 0%, #1a1008 50%, #ffd60a33 100%)",
    "linear-gradient(135deg, #1a2a3d 0%, #0a101a 50%, #64d2ff33 100%)",
    "linear-gradient(135deg, #3d1a2a 0%, #1a0a10 50%, #ff453a33 100%)",
  ];

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  const toastEl = $("#toast");
  const modal = $("#gameModal");
  const state = { site: null, changelogShown: 2 };

  function flash(text, isError = false) {
    if (!toastEl) return;
    toastEl.textContent = text;
    toastEl.classList.toggle("error", isError);
    toastEl.classList.add("show");
    setTimeout(() => toastEl.classList.remove("show"), 2800);
  }

  async function api(path, options = {}) {
    const base = window.ALLERAL_API || "";
    const res = await fetch(base + path, {
      headers: { "Content-Type": "application/json", ...(options.headers || {}) },
      ...options,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok || data.ok === false) {
      throw new Error(data.error || `Request failed (${res.status})`);
    }
    return data;
  }

  function gradientFor(id, index) {
    let hash = index;
    for (let i = 0; i < (id || "").length; i += 1) hash += id.charCodeAt(i);
    return GRADIENTS[hash % GRADIENTS.length];
  }

  function setActiveNav() {
    const id = location.hash.replace("#", "") || "home";
    $$(".nav-links a[data-section]").forEach((a) => a.classList.toggle("active", a.dataset.section === id));
  }

  function titleCaseStatus(value) {
    const text = String(value || "working").toLowerCase();
    return text.charAt(0).toUpperCase() + text.slice(1);
  }

  function afterRender() {
    window.AlleralEffects?.observeReveals?.();
  }

  function renderAnnouncement(site) {
    const el = $("#announcement");
    const text = (site.announcement || "").trim();
    if (!el) return;
    el.classList.toggle("hidden", !text);
    if (text) el.textContent = text;
  }

  function renderHero(site) {
    const brand = site.brand || "Alleral";
    $("#heroBrand").textContent = brand.toUpperCase();
    $("#tagline").textContent = site.tagline || "The ultimate Roblox script library.";
    $("#loaderVersion").textContent = site.loaderVersion || "—";
    $("#scriptsUpdated").textContent = site.scriptsUpdatedAt || "—";
    $("#loadstringCode").textContent = site.loadstring || "";
    $("#gameCount").textContent = String(Object.keys(site.games || {}).length);
  }

  function openGameModal(game, gradient) {
    if (!modal) return;
    $("#modalTitle").textContent = game.name || game.id;
    $("#modalMeta").textContent = `Version ${game.version || "?"} · ${game.id || ""}`;
    $("#modalDesc").textContent = game.description || game.message || "No description available.";
    const status = (game.status || "working").toLowerCase();
    const badge = $("#modalBadge");
    badge.textContent = titleCaseStatus(status);
    badge.className = `status-chip ${status}`;
    $("#modalArt").style.background = gradient;
    const roblox = $("#modalRoblox");
    if (game.robloxUrl) {
      roblox.href = game.robloxUrl;
      roblox.classList.remove("hidden");
    } else {
      roblox.classList.add("hidden");
    }
    modal.showModal();
  }

  function renderGames(site) {
    const root = $("#gamesGrid");
    root.innerHTML = "";
    const games = Object.values(site.games || {}).sort((a, b) => (a.name || "").localeCompare(b.name || ""));
    if (!games.length) {
      root.innerHTML = '<p class="empty reveal">No games listed yet.</p>';
      afterRender();
      return;
    }
    games.forEach((game, i) => {
      const status = (game.status || "working").toLowerCase();
      const statusLabel = titleCaseStatus(status);
      const grad = gradientFor(game.id, i);
      const card = document.createElement("article");
      card.className = "game-card card-enter";
      card.style.animationDelay = `${i * 0.06}s`;
      card.innerHTML = `
        <div class="game-art" style="background:${grad}"></div>
        <div class="game-body">
          <h3>${game.name || game.id}</h3>
          <div class="game-meta">
            <span class="status-chip ${status}">${statusLabel}</span>
            <span class="game-version">v${game.version || "?"}</span>
          </div>
          <p class="game-desc">${game.description || game.message || ""}</p>
          <button class="btn-link" type="button">View Details →</button>
        </div>
      `;
      card.addEventListener("click", (e) => {
        if (e.target.closest("a")) return;
        openGameModal(game, grad);
      });
      root.appendChild(card);
    });

    const bugGame = $("#bugGame");
    if (bugGame) {
      const current = bugGame.value;
      bugGame.innerHTML = '<option value="">Select a game</option>';
      games.forEach((g) => {
        const opt = document.createElement("option");
        opt.value = g.name || g.id;
        opt.textContent = g.name || g.id;
        bugGame.appendChild(opt);
      });
      if (current) bugGame.value = current;
    }
    afterRender();
  }

  function renderChangelog(site, reset = true) {
    const root = $("#changelog");
    const entries = site.changelog || [];
    if (reset) {
      root.innerHTML = "";
      state.changelogShown = 2;
    }
    const slice = entries.slice(0, state.changelogShown);
    slice.forEach((entry, i) => {
      if (root.children[i]) return;
      const node = document.createElement("article");
      node.className = "changelog-card reveal";
      node.innerHTML = `
        <h3>${entry.title || "Update"}</h3>
        <p class="cl-date">${entry.date || ""}</p>
        <ul>${(entry.items || []).map((item) => `<li>${item}</li>`).join("")}</ul>
      `;
      root.appendChild(node);
    });
    const btn = $("#loadMoreChangelog");
    if (btn) {
      const hasMore = state.changelogShown < entries.length;
      btn.classList.toggle("hidden", !hasMore);
    }
    afterRender();
  }

  function renderFaq(site) {
    const root = $("#faq");
    root.innerHTML = "";
    (site.faq || []).forEach((item) => {
      const node = document.createElement("details");
      node.className = "reveal";
      node.innerHTML = `<summary>${item.q || "Question"}</summary><p>${item.a || ""}</p>`;
      root.appendChild(node);
    });
    afterRender();
  }

  function renderBugCategories(site) {
    const select = $("#bugCategory");
    if (!select) return;
    select.innerHTML = "";
    (site.bugCategories || ["Other"]).forEach((cat) => {
      const opt = document.createElement("option");
      opt.value = cat;
      opt.textContent = cat;
      select.appendChild(opt);
    });
  }

  function renderAccess(site) {
    const cfg = window.ALLERAL_CONFIG || {};
    const links = site.links || {};
    const primary = links.website || cfg.publicUrl || window.location.origin + "/";
    const mirror = links.mirror || cfg.mirrorUrl || "";

    const primaryEl = $("#primaryUrl");
    const mirrorEl = $("#mirrorUrl");
    const mirrorLink = $("#mirrorLink");
    const footerEl = $("#footerSiteLink");

    if (primaryEl) primaryEl.textContent = primary;
    if (mirrorEl) mirrorEl.textContent = mirror || "not available";
    if (mirrorLink && mirror) mirrorLink.href = mirror;
    if (footerEl) footerEl.href = primary;
  }

  async function loadSite() {
    const data = await api("/api/site");
    state.site = data;
    const brand = data.brand || "Alleral";
    document.title = `${brand} — Script Library`;
    $("#brandName").textContent = brand;
    renderAccess(data);
    renderAnnouncement(data);
    renderHero(data);
    renderGames(data);
    renderChangelog(data, true);
    renderFaq(data);
    renderBugCategories(data);
  }

  async function copyText(text, msg) {
    try {
      await navigator.clipboard.writeText(text);
      flash(msg);
    } catch {
      flash("Copy failed", true);
    }
  }

  async function checkLiveStatus() {
    const el = $("#liveStatus");
    if (!el) return;
    const base = window.ALLERAL_API || "";
    try {
      const res = await fetch(base + "/health", { cache: "no-store" });
      const data = await res.json();
      if (data.ok) {
        el.className = "status-pill online";
        el.innerHTML = '<span class="status-dot"></span>Online';
        el.title = `Relay v${data.version || "?"}`;
      } else throw new Error();
    } catch {
      el.className = "status-pill offline";
      el.innerHTML = '<span class="status-dot"></span>Offline';
    }
  }

  async function copyLoadstring() {
    const text = state.site?.loadstring || $("#loadstringCode")?.textContent || "";
    await copyText(text, "Script copied to clipboard");
  }

  async function submitBug(ev) {
    ev.preventDefault();
    const err = $("#bugError");
    err.textContent = "";
    try {
      await api("/api/bug-report", {
        method: "POST",
        body: JSON.stringify({
          category: $("#bugCategory").value,
          severity: $("#bugSeverity").value,
          game: $("#bugGame").value,
          robloxUser: $("#bugUser").value.trim(),
          executor: $("#bugExecutor").value.trim(),
          contact: $("#bugContact").value.trim(),
          description: $("#bugDescription").value.trim(),
          steps: $("#bugSteps").value.trim(),
        }),
      });
      $("#bugForm").reset();
      flash("Report submitted");
    } catch (e) {
      err.textContent = e.message;
      flash(e.message, true);
    }
  }

  async function submitFeature(ev) {
    ev.preventDefault();
    const err = $("#featureError");
    err.textContent = "";
    try {
      await api("/api/feature-request", {
        method: "POST",
        body: JSON.stringify({
          robloxUser: $("#featureUser").value.trim(),
          game: $("#featureGame").value.trim(),
          idea: $("#featureIdea").value.trim(),
        }),
      });
      $("#featureForm").reset();
      flash("Idea submitted");
    } catch (e) {
      err.textContent = e.message;
      flash(e.message, true);
    }
  }

  function bindTabs() {
    $$(".support-tabs button").forEach((btn) => {
      btn.addEventListener("click", () => {
        const panel = btn.dataset.panel;
        $$(".support-tabs button").forEach((b) => b.classList.toggle("active", b === btn));
        $$("[data-panel-body]").forEach((body) => body.classList.toggle("hidden", body.dataset.panelBody !== panel));
      });
    });
  }

  function bindModal() {
    $$(".modal-close, .modal-close-btn").forEach((btn) => {
      btn.addEventListener("click", () => modal?.close());
    });
    modal?.addEventListener("click", (e) => {
      if (e.target === modal) modal.close();
    });
  }

  function bindMobileNav() {
    const toggle = $("#navToggle");
    const nav = $("#mainNav");
    toggle?.addEventListener("click", () => nav?.classList.toggle("open"));
    $$(".nav-links a").forEach((a) => a.addEventListener("click", () => nav?.classList.remove("open")));
  }

  $("#copyLoadstring")?.addEventListener("click", copyLoadstring);
  $("#copyPrimaryUrl")?.addEventListener("click", () => {
    copyText($("#primaryUrl")?.textContent || "", "Link copied");
  });
  $("#loadMoreChangelog")?.addEventListener("click", () => {
    state.changelogShown += 3;
    renderChangelog(state.site, false);
  });
  $("#bugForm")?.addEventListener("submit", submitBug);
  $("#featureForm")?.addEventListener("submit", submitFeature);
  window.addEventListener("hashchange", setActiveNav);

  $("#footerYear").textContent = String(new Date().getFullYear());

  bindTabs();
  bindModal();
  bindMobileNav();
  setActiveNav();
  checkLiveStatus();
  setInterval(checkLiveStatus, 60000);
  loadSite().catch((e) => flash(e.message, true));
})();

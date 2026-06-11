(() => {
  const STORAGE_KEY = "alleral_gate_ok";
  const cfg = window.ALLERAL_CONFIG || {};
  const siteKey = (cfg.turnstileSiteKey || "").trim();

  function randomRay() {
    const hex = "0123456789abcdef";
    let id = "";
    for (let i = 0; i < 16; i += 1) id += hex[Math.floor(Math.random() * 16)];
    return id;
  }

  function finish(gate) {
    sessionStorage.setItem(STORAGE_KEY, "1");
    gate.classList.add("cf-gate-out");
    document.documentElement.classList.remove("cf-gate-lock");
    setTimeout(() => gate.remove(), 650);
  }

  if (sessionStorage.getItem(STORAGE_KEY)) return;

  document.documentElement.classList.add("cf-gate-lock");

  const gate = document.createElement("div");
  gate.id = "cfGate";
  gate.setAttribute("role", "dialog");
  gate.setAttribute("aria-label", "Security check");
  gate.innerHTML = `
    <div class="cf-gate-card">
      <div class="cf-gate-top">
        <div class="cf-cloud" aria-hidden="true">
          <svg viewBox="0 0 64 40" width="52" height="32">
            <path fill="#f6821f" d="M19 31c-6.1 0-11-4.9-11-11 0-5.2 3.6-9.6 8.5-10.8C18.2 4.8 23.5 1 29.6 1c7.2 0 13.2 5.1 14.6 11.9 5.5.4 9.8 5.1 9.8 10.8 0 6.1-4.9 11-11 11H19z"/>
            <path fill="#fbad41" d="M19 31h24.4c6.1 0 11-4.9 11-11 0-5.7-4.3-10.4-9.8-10.8C43.2 2.3 37.2-2.8 30 1c-5.1 0-9.6 2.8-11.6 6.9C13.5 9.1 10 13.5 10 18.5c0 6.1 4.9 11 9 11z" opacity=".55"/>
          </svg>
        </div>
        <div class="cf-gate-brand">
          <strong>alleral<span class="cf-dot">.</span>hub</strong>
          <span>checking your connection</span>
        </div>
      </div>
      <h1 class="cf-gate-title">Just a moment…</h1>
      <p class="cf-gate-lead">We need to review the security of your connection before continuing.</p>
      <ul class="cf-steps" id="cfSteps">
        <li data-step="browser"><span class="cf-check"></span> Verifying browser</li>
        <li data-step="human"><span class="cf-check"></span> Checking if you are human</li>
        <li data-step="edge"><span class="cf-check"></span> Waiting for alleral.hub to respond</li>
      </ul>
      <div class="cf-progress"><div class="cf-progress-bar" id="cfBar"></div></div>
      <div id="cfTurnstile" class="cf-turnstile ${siteKey ? "" : "hidden"}"></div>
      <p class="cf-ray">Ray ID: <code id="cfRay">${randomRay()}</code></p>
      <p class="cf-powered">Performance &amp; security by <strong>Cloudflare</strong></p>
    </div>
  `;

  document.body.prepend(gate);

  const steps = gate.querySelectorAll(".cf-steps li");
  const bar = gate.querySelector("#cfBar");
  let stepIndex = 0;

  function tickStep() {
    if (stepIndex > 0) steps[stepIndex - 1].classList.add("done");
    if (stepIndex < steps.length) {
      steps[stepIndex].classList.add("active");
      bar.style.width = `${((stepIndex + 1) / (steps.length + 1)) * 100}%`;
      stepIndex += 1;
      return stepIndex <= steps.length;
    }
    return false;
  }

  tickStep();
  const stepTimer = setInterval(() => {
    if (!tickStep()) clearInterval(stepTimer);
  }, 700);

  function runSimulatedCheck() {
    bar.style.width = "100%";
    steps.forEach((s) => s.classList.add("done"));
    setTimeout(() => finish(gate), 450);
  }

  if (siteKey) {
    const script = document.createElement("script");
    script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";
    script.async = true;
    script.onload = () => {
      const mount = gate.querySelector("#cfTurnstile");
      mount.classList.remove("hidden");
      window.turnstile.render(mount, {
        sitekey: siteKey,
        theme: "dark",
        callback: () => {
          clearInterval(stepTimer);
          runSimulatedCheck();
        },
        "error-callback": runSimulatedCheck,
        "expired-callback": () => window.turnstile.reset(mount),
      });
    };
    script.onerror = () => {
      setTimeout(runSimulatedCheck, 1800);
    };
    document.head.appendChild(script);
  } else {
    setTimeout(runSimulatedCheck, 2400);
  }
})();

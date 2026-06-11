window.ALLERAL_API = window.ALLERAL_API || "https://alleral-telemetry-production.up.railway.app";

window.ALLERAL_CONFIG = {
  /** Primary URL players should bookmark (shown on the site). */
  publicUrl: "https://alleral-telemetry-production.up.railway.app/",
  /** GitHub Pages mirror — enable Pages in repo settings first. */
  mirrorUrl: "https://evanbackup1256-ship-it.github.io/kick/",
  /**
   * Cloudflare Turnstile site key (public). Leave empty for a styled security check only.
   * Create at: Cloudflare Dashboard → Turnstile → Add site → embed widget.
   * Set TURNSTILE_SECRET_KEY on Railway if you verify server-side later.
   */
  turnstileSiteKey: "",
};

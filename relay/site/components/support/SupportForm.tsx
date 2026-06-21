"use client";

import { useState, type FormEvent } from "react";
import { Send, CheckCircle, Copy, ArrowRight, AlertTriangle, Loader2 } from "lucide-react";
import { SupportSelect } from "./SupportSelect";

export function SupportForm() {
  const [sending, setSending] = useState(false);
  const [done, setDone] = useState(false);
  const [ticketId, setTicketId] = useState("");
  const [copied, setCopied] = useState(false);
  const [err, setErr] = useState("");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [discord, setDiscord] = useState("");
  const [roblox, setRoblox] = useState("");
  const [issueType, setIssueType] = useState("Bug Report");
  const [message, setMessage] = useState("");

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setErr("");

    if (!name.trim() || !email.trim() || !message.trim()) {
      setErr("Name, email, and message are required.");
      return;
    }

    setSending(true);
    await new Promise((r) => setTimeout(r, 1200));

    const id = `ALLERAL-2026-${String(Math.floor(1000 + Math.random() * 9000))}`;
    setTicketId(id);
    setSending(false);
    setDone(true);
  };

  const copyId = () => {
    navigator.clipboard.writeText(ticketId);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (done) {
    return (
      <div className="surface-card p-8 text-center">
        <div className="mx-auto mb-5 flex h-16 w-16 items-center justify-center rounded-full bg-violet/10">
          <CheckCircle className="h-8 w-8 text-violet-bright" />
        </div>
        <h3 className="text-xl font-bold text-text-strong">Ticket created</h3>
        <p className="mb-5 mt-2 text-sm text-muted">We&apos;ll get back to you on Discord.</p>
        <div className="surface-card mb-5 inline-block px-5 py-3">
          <code className="font-mono text-lg text-cyan-bright">{ticketId}</code>
        </div>
        <div className="flex justify-center gap-3">
          <button type="button" className="btn btn-primary" onClick={copyId}>
            {copied ? "Copied" : (
              <>
                <Copy className="h-4 w-4" /> Copy ID
              </>
            )}
          </button>
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => {
              setDone(false);
              setName("");
              setEmail("");
              setDiscord("");
              setRoblox("");
              setIssueType("Bug Report");
              setMessage("");
            }}
          >
            New ticket
          </button>
        </div>
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="surface-card p-6 md:p-8">
      <div className="mb-4 grid gap-4 md:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-mono text-xs uppercase tracking-wider text-muted-2">Name</label>
          <input value={name} onChange={(e) => setName(e.target.value)} className="input-field" />
        </div>
        <div>
          <label className="mb-1.5 block font-mono text-xs uppercase tracking-wider text-muted-2">Email</label>
          <input value={email} onChange={(e) => setEmail(e.target.value)} type="email" className="input-field" />
        </div>
      </div>
      <div className="mb-4 grid gap-4 md:grid-cols-2">
        <div>
          <label className="mb-1.5 block font-mono text-xs uppercase tracking-wider text-muted-2">Discord</label>
          <input value={discord} onChange={(e) => setDiscord(e.target.value)} className="input-field" />
        </div>
        <div>
          <label className="mb-1.5 block font-mono text-xs uppercase tracking-wider text-muted-2">Roblox Username</label>
          <input value={roblox} onChange={(e) => setRoblox(e.target.value)} className="input-field" />
        </div>
      </div>
      <div className="mb-4 grid gap-4 md:grid-cols-2">
        <SupportSelect value={issueType} onChange={setIssueType} label="Issue Type" />
        <div>
          <label className="mb-1.5 block font-mono text-xs uppercase tracking-wider text-muted-2">Game / Script</label>
          <input className="input-field" />
        </div>
      </div>
      <div className="mb-4">
        <label className="mb-1.5 block font-mono text-xs uppercase tracking-wider text-muted-2">Message</label>
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          rows={4}
          className="input-field resize-none"
        />
      </div>

      {err ? (
        <div className="mb-4 flex items-center gap-2 rounded-xl border border-red/20 bg-red/10 px-4 py-3">
          <AlertTriangle className="h-4 w-4 shrink-0 text-red" />
          <p className="text-xs text-red/90">{err}</p>
        </div>
      ) : null}

      <button type="submit" className="btn btn-primary w-full" disabled={sending}>
        {sending ? (
          <>
            <Loader2 className="h-4 w-4 animate-spin" /> Sending...
          </>
        ) : (
          <>
            <Send className="h-4 w-4" /> Submit <ArrowRight className="h-4 w-4" />
          </>
        )}
      </button>
    </form>
  );
}
# Mintlify reference — generate the wiki (Chrome DevTools MCP)

Goal: produce (or refresh) `https://mintlify.wiki/<owner>/<repo>` for the
project's GitHub repo, so Phase 3 can read it as the source of truth.

Mintlify auto-generates the wiki from the connected GitHub repo — you don't write
docs by hand here. For a **public** repo, generation needs no sign-in at all:
`mintlify.wiki/<owner>/<repo>` resolves anonymously, and the only field it asks
for is a notify-me email — not a credential. You can drive that whole flow
yourself. Only hand off to the user when the flow actually hits a **GitHub OAuth
authorize/install** screen (private repos, or a repo Mintlify hasn't indexed
yet) — that's a real access grant and stays the user's action.

## Account

The Chrome DevTools MCP drives its **own dedicated Chrome profile**, not the
personal one, so sessions there start signed out. The profile is persistent: if
a step needs the user signed in to GitHub or Mintlify, hand off once and it
carries over to later runs.

The user's Mintlify notify-email is **`luisgir827@gmail.com`**. Typing this into
a plain "email to notify" field is not a credential and not a sign-in — you may
enter it yourself and click through (see Steps). What you must **never** type
yourself: a password, an OTP/magic-link code, or click an "Authorize"/"Install"
button on a GitHub OAuth screen — if one of those appears, stop and hand off:

> "Mintlify is asking to authorize GitHub for this repo — please click
>  Authorize/Install yourself, then tell me when it's done."

## Steps

1. **Open a fresh page** with `new_page` (`list_pages` first if you want to see
   what's already open — don't reuse an unrelated one). Use one page per repo if
   you're generating several — they run independently, so you can kick off
   multiple generations in parallel and come back to poll each one with
   `select_page`.
2. **Navigate directly** to `https://mintlify.wiki/<owner>/<repo>` with
   `navigate_page` (skip the `/explore` search step — it's slower and
   unnecessary once you have the repo).
3. **Read the page** with `take_snapshot` (`take_screenshot` when you need to
   see it). Three outcomes:
   - **Already generated** — content renders immediately. Skip to Phase 3.
   - **"Create a new site" / "Content is being generated"** — a plain email
     field asking who to notify. `fill` it with `luisgir827@gmail.com` yourself
     and `click` **Create content** / **Notify me**. No further action needed
     from the user.
   - **A GitHub authorize/install screen** — stop and hand off (see Account).
4. **Wait for generation**, 15–30 minutes per the page's own estimate. Don't
   poll in a tight loop or sleep blindly for the whole window — kick off
   generation for everything you need in this session first (one page each),
   then move on to other work and come back to reload
   `https://mintlify.wiki/<owner>/<repo>` periodically.
5. **Confirm the URL resolves** to real content, then move to Phase 3 (read it).

## Already generated?

If `https://mintlify.wiki/<owner>/<repo>` already exists (the user may have made
it before), you can skip straight to reading it. But if the repo changed
materially since, offer to **regenerate** first so the Notion write reflects
current code — a stale wiki produces a stale portfolio page.

## Rabbit-hole guard

If the browser flow stalls — repeated failed clicks, a `uid` that no longer
resolves even after a fresh `take_snapshot`, an unexpected paywall or gate, or
generation that never finishes —
stop after a couple of attempts, tell the user exactly what you saw, and ask how
to proceed. Don't loop on the same failing action. As a fallback, the repo itself
(README, docs/, source) is enough raw material to write the Notion content; the
wiki is the preferred source, not the only one.

## Optional: capture screenshots for placeholders

While you have the live app/wiki open, you *may* capture screenshots to hand to
the user for the image placeholders — but you can't upload binaries into Notion
file properties via the MCP, so these are for the user to drop in manually. Don't
block on this; the placeholders (see `notion.md`) are the deliverable.

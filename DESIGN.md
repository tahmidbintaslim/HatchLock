---
name: HatchLock
description: Stop your AI from hiding type errors.
colors:
  ground: "#f7f8fe"
  ink: "#1b1850"
  text: "#2d2b5c"
  muted: "#5a5885"
  line: "#dfe1f3"
  card: "#ffffff"
  panel: "#24206b"
  panel-text: "#e9e8ff"
  panel-muted: "#b9b6ee"
  accent: "#4a43d8"
  blocked: "#c23a2c"
  blocked-soft: "#fdecea"
  pass: "#17734a"
  pass-soft: "#e5f5ec"
  wash-periwinkle: "#cfd3ff"
  wash-peach: "#ffe1d6"
  icon-slash: "#ef5b4c"
typography:
  display:
    fontFamily: "Bricolage Grotesque Variable, system-ui, sans-serif"
    fontSize: "4.25rem"
    fontWeight: 700
    lineHeight: 1.02
    letterSpacing: "-0.035em"
  heading:
    fontFamily: "Bricolage Grotesque Variable, system-ui, sans-serif"
    fontSize: "2.75rem"
    fontWeight: 700
    lineHeight: 1.08
    letterSpacing: "-0.03em"
  body:
    fontFamily: "Onest Variable, system-ui, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.6
  code:
    fontFamily: "JetBrains Mono Variable, ui-monospace, monospace"
    fontSize: "0.875em"
rounded:
  code: "8px"
  card: "16px"
  panel: "35px"
  pill: "999px"
spacing:
  gutter: "1.25rem"
  section: "6.5rem"
  page-max: "72rem"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "#ffffff"
    rounded: "{rounded.pill}"
    padding: "0.95rem 1.6rem"
  window-card:
    backgroundColor: "{colors.card}"
    textColor: "{colors.text}"
    rounded: "{rounded.card}"
  checks-panel:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.panel-text}"
    rounded: "{rounded.panel}"
  status-blocked:
    backgroundColor: "{colors.blocked-soft}"
    textColor: "{colors.blocked}"
  status-pass:
    backgroundColor: "{colors.pass-soft}"
    textColor: "{colors.pass}"
---

# HatchLock design system

## Overview

Calm daylight. HatchLock blocks things, but it should feel like a seatbelt, not an alarm. The reference is the friendly consumer browser-extension page (momentumdash.com): a light ground washed with soft colour from the corners, big confident rounded headlines, one dark pill button, and the product shown as floating window cards. It deliberately avoids the dark page with a neon accent and fake terminal that most developer tools use.

Voice: easy and customer-friendly. Lead with what the reader gets. Short sentences, plain words, no hype and no superlatives. Never claim users, ratings or numbers that do not exist.

## Colors

- **Ground** `#f7f8fe` with two corner washes (periwinkle top right, peach left). The washes are atmosphere only; never put text on a saturated wash.
- **Ink** `#1b1850` for headings, the primary button and the footer. **Text** `#2d2b5c`, **muted** `#5a5885` (both pass 4.5:1 on ground).
- **Panel** `#24206b`: one deep indigo block per page, used for the three checks.
- **Blocked** `#c23a2c` on `#fdecea`, **pass** `#17734a` on `#e5f5ec`. These two mean exactly "blocked" and "passes". Always pair them with an icon and the word; never use them for decoration.
- **Accent** `#4a43d8` for links and focus rings.

## Typography

- Display and headings: Bricolage Grotesque, weight 700, tight tracking, balanced wrapping.
- Body: Onest, 17px, line-height 1.6, measure under 65 characters.
- JetBrains Mono for code, commands and real hook output only, never as a "technical" costume.
- Fonts are self-hosted through `@fontsource-variable/*`.

## Layout

- Page width `min(72rem, 100% - 2.5rem)`. Sections separated by generous vertical space (up to 6.5rem).
- Hero is two columns: copy left, overlapping before/after window cards right, joined by a hand-drawn arrow. Under 860px everything stacks to one column and the arrow is hidden.
- Lists are ruled rows (a hairline between items), not grids of identical cards.

## Elevation & Depth

One soft shadow for floating cards: `0 18px 40px -18px rgb(36 32 107 / 0.28), 0 2px 6px rgb(36 32 107 / 0.06)`. Buttons lift 2px on hover. No glows, no glass.

## Shapes

Pills for buttons, 16px for cards, 35px for the big panel and footer top. The app icon is a rounded indigo square holding a white padlock with two coral slashes inside: the `//` of a suppression comment, locked up.

## Components

- **Primary button**: ink pill, white label, trailing arrow icon.
- **Window card**: white, three grey dots and a label in the header, then code or status rows.
- **Status row**: full-width tinted strip with icon + words ("Blocked. Fix the type instead." / "Type check passes").
- **Checks panel**: indigo block; three steps on a vertical line, each with a white round icon, a heading, one sentence and a real example message.
- **Command row**: white card with a step label, the command, and a Copy pill that confirms with "Copied".
- **FAQ**: native `<details>` with a chevron.

## Do's and Don'ts

- Do show real hook messages and real commands as proof. Don't invent testimonials, counts or badges.
- Do keep the page light. Don't add a dark theme by inverting; design it if it is ever needed.
- Do draw icons as 2px-stroke SVG. Don't use emoji as icons.
- Don't use Anthropic or OpenAI logos, or wording that implies endorsement.
- Motion: one moment only, the "With HatchLock" card revealing its rows in order. Respect `prefers-reduced-motion`.

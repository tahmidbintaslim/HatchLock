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
    fontFamily: "Onest Variable, system-ui, sans-serif"
    fontSize: "5.75rem"
    fontWeight: 500
    lineHeight: 1.08
    letterSpacing: "-0.03em"
  heading:
    fontFamily: "Onest Variable, system-ui, sans-serif"
    fontSize: "3rem"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "-0.022em"
  body:
    fontFamily: "Onest Variable, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.6
  code:
    fontFamily: "JetBrains Mono Variable, ui-monospace, monospace"
    fontSize: "0.8125rem"
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

The landing page follows the layout and manner of shiplight.ai, at the owner's request, using HatchLock's own colours and icon: a white page with a faint grid, a very large medium-weight headline with one phrase in the accent colour, a ribbon of fine lines, square-cornered buttons, a dark tabbed install box, a strip of pastel feature cards over an accent band of numbers, numbered "how it works" rows with dark terminals, a two-column FAQ and a navy footer with a giant faded wordmark.

Voice: easy and customer-friendly. Lead with what the reader gets. Short sentences, plain words, no hype and no superlatives. Never claim users, ratings, logos or numbers that do not exist: the reference site's customer logos and testimonials are deliberately not reproduced.

## Colors

- Page `#ffffff`, tinted sections `#f6f7fd`, hairlines `#e3e5f4`.
- **Ink** `#1b1850` for headings; **text** `#2d2b5c`; **muted** `#5a5885`.
- **Accent** `#4a43d8` for the highlighted headline phrase, primary buttons, links, the numbers band and step numbers.
- **Navy** `#171448` for the footer; **terminal** `#14122e` for install and example boxes.
- Pastel cards: lavender `#e2e4ff`, mint `#d6efe0`, rose `#fddcd7`, peach `#ffe9d2`.
- Terminal status colours: coral `#ff9d8f` for blocked/failed, green `#8fe0b6` for passing, always with a symbol or word.
- Icon: indigo `#24206b` square, white padlock, coral `#ef5b4c` slashes.

## Typography

- Onest for everything on the site: headlines at weight 500 with tight tracking (h1 up to 92px, h2 48px), body 16-20px.
- JetBrains Mono for commands, code, terminal output and the small uppercase section labels.
- The brand board in Figma also lists Bricolage Grotesque for headings; the site does not use it, to match the reference's plain medium-weight headlines.

## Layout

- Content width 76rem. Sections alternate white and tint, 6rem vertical padding.
- "How it works" rows alternate copy and terminal left/right, separated by hairlines, each with a numbered mono label.
- Under 900px everything stacks; under 560px cards and footer go to one column.

## Elevation & Depth

Flat. Only the dark terminals and language cards cast a soft offset shadow.

## Shapes

6px corners on buttons, tabs and terminals; square pastel cards and bands; pills only for the small dark tags.

## Components

- **Button**: accent fill with white text, or white with accent border and text; a small navy variant.
- **Install box**: dark, tabbed (Claude Code / Local clone / Update), commands prefixed with `$`, copy button that turns green when copied.
- **Outcome card**: pastel block with a line icon, title, two sentences and a text link.
- **Numbers band**: accent block; each number sits in a white box.
- **Step row**: numbered mono label, heading, paragraph, link, and a terminal showing a real HatchLock message.
- **FAQ**: native `<details>` with a boxed chevron.

## Do's and Don'ts

- Do show real hook messages and real commands as proof. Don't invent testimonials, customer logos or statistics.
- Don't copy the reference site's wording, logo or images; only its layout conventions.
- Don't use Anthropic or OpenAI logos, or wording that implies endorsement.
- Keep icons as 1.5-2px stroke SVG. No emoji icons.

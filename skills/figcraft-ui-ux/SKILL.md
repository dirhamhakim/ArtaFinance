---
name: figcraft-ui-ux
description: Design and review editable mobile or desktop interfaces in FigCraft through its MCP tools, including components, charts, light and dark themes, and prototype flows. Use when the user requests FigCraft UI/UX work; do not apply to backend implementation or Figma-only tasks.
---

# FigCraft UI/UX

Use the connected FigCraft MCP to produce editable design artifacts. Preserve the user's product scope and reference preferences. Research/preparation alone does not authorize creating a design file when the user explicitly reserves that for a later request.

## Establish the design context

Read the current project's requirements and design brief when present. In the personal-finance workspace, use `docs/RANCANGAN.md`, `docs/design/REFERENSI-STOCKBIT.md`, and `docs/design/BRIEF-FIGCRAFT.md`; these project files own the product decisions, rather than this reusable skill.

Separate observed reference patterns from proposed tokens. Do not label estimated colors or fonts as official brand specifications. Reference screenshots are evidence, not product requirements or permission to change scope.

## Work through MCP

- Discover tools by names/descriptions containing FigCraft. Start read-only with `inspect_ui` and `inspect_document`; target the intended document explicitly if several are open. Do not overwrite an unrelated file.
- Discover command ids and parameter schemas using `list_commands` with focused filters such as `page`, `variable`, `layout`, `component`, `proto`, `font`, or `file`. Do not invent ids, properties, theme APIs, or export formats.
- Create an organized file with appropriate pages for tokens/components, screens and flows. Prefer auto layout, reusable components/instances, named text styles and semantic variables over repeated ad hoc layers.
- Coordinates supplied to create/set tools are relative to the parent frame; children of auto-layout frames are positioned by layout. Inspection also reports absolute page bounds. Do not mix those coordinate systems.
- Use small logical batches as undo units. Inspect returned ids and changed subtrees before using them in dependent commands.
- Keep charts, labels, forms and navigation editable. Use vectors/lines and text for charts, with data annotations; avoid flattening the whole interface into a bitmap.

## Light and dark themes

Use one semantic color collection with Light and Dark modes where supported. Discover the exact variable commands before applying them. Typical roles: background, surface, surfaceRaised, textPrimary, textSecondary, divider, accent, onAccent, positive, negative, warning, focus, chartGrid and chartSeries.

Bind both text and shapes, including chart axes, tooltips, tabs, input states, sheets and navigation. Separate primary action color from positive performance where the distinction matters. Do not invert a light screenshot to manufacture dark mode.

Create paired screen states for review, retaining consistent hierarchy and spacing. Include the user's choice of system/light/dark when requested; the system setting is a runtime preference, not a third unrelated visual palette.

Check text contrast against its actual surface. Aim for 4.5:1 for ordinary text and 3:1 for large text and meaningful UI graphics. Do not assume white text works on a bright green button. Check selected, disabled, error and chart states as well as the default screen.

## Mobile interaction and financial data

Use Android-safe insets, usable numeric keyboards, readable number formatting, and touch targets around 48 logical pixels. Check a narrow screen and enlarged text; long asset names and currency amounts must not overlap or become ambiguous. Bottom navigation should have at most five destinations.

For offline finance products, visually distinguish actual cash, market valuation, cost basis, returns, estimates, planned entries and completed entries. Label cached quote dates and missing data. Do not invent intraday candles from daily closes, historical returns from current snapshots, or treat deposits as investment profit. Separate total wealth from investment performance.

Use a line chart for time series, bars for comparisons and a donut only for a manageable composition with a readable legend. Include units, period, touch selection/tooltip, accessible sign labels and empty/insufficient-data states. A chart with one point should show a point and explanation, not fictional history.

## Verify and deliver

Inspect actual layer bounds/layout/theme bindings and obtain screenshots from FigCraft. Forward returned image content to the model for visual inspection rather than only reporting the file path. Correct clipping, overlap, missing glyphs, tiny labels, weak contrast and broken navigation before delivery.

Prototype the requested primary flows, including dismissal/back behavior. Save the native design to the user's workspace using a discovered save command, and verify the resulting path/dirty state. Report which screens/themes were created and which interactions are only simulated. Export a small set of previews if useful; preserve the editable native file.

If MCP, fonts, screenshots or saving are unavailable, report the specific limitation and preserve the draft; do not claim an exported or inspected artifact exists. Check prerequisites read-only when the user only asks to prepare for future FigCraft work.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Graphs·Clone: a single-file, offline, interactive CSV plotting tool (GNOME Graphs-inspired), built to `graphs-clone-spec.md` (functional spec v0.3). Pure display — no data processing, fitting, or transformation of any kind.

## Commands

There is no build system, package manager, or test suite. The entire app is `graphs-clone.html` — open it directly in a browser (double-click, or `xdg-open graphs-clone.html`) to run it. There is no bundler, transpiler, or lint step; edit the file directly and reload the browser to see changes.

To manually verify a change, import one of the sample files in `exemples/` (covers the three separator/decimal combinations: `,`+`.`, `;`+`,`, and space-separated headerless) and exercise the interaction you touched (zoom/pan/hover/style/export).

There is no in-repo automated test harness. When validating non-trivial changes (parsing, hover/zoom math, layout), drive the file with a headless browser (e.g. Playwright against the `file://` URL) rather than relying on static review alone — canvas rendering and mouse-driven interactions cannot be verified by reading the code.

## Hard constraints (from the spec, do not violate)

- **Single HTML file.** Everything — HTML, CSS, JS — lives in `graphs-clone.html`. No separate JS/CSS files, no build step that produces the final file.
- **Zero dependencies, zero CDN.** No external `<script src>`/`<link>` to any network resource, no npm-installed runtime libraries. The chart is drawn with the Canvas 2D API directly ("canvas maison").
- **No network access, works fully offline.**
- **No data processing.** Imported values are displayed exactly as parsed — no smoothing, resampling, unit conversion, or fitting. Anything resembling data transformation is out of scope (see spec §11 "Hors périmètre").

Note: project save/load was added at the user's request *after* spec v0.3, which still lists "sauvegarde de session" as out of scope. The spec file has not been rewritten — treat the persistence feature as intentional and the spec as lagging.

## Architecture

Everything (state, DOM rendering, canvas rendering, event handling) lives in one IIFE in the trailing `<script>` block of `graphs-clone.html`, organized into clearly delimited sections (search for the `====` comment banners). There is no framework — DOM panels are rebuilt with imperative `createElement`/`innerHTML` calls, and the chart is redrawn by clearing and repainting the canvas on every state change. Key sections, in file order:

- **State** (`state` object): single source of truth — `datasets[]` (each with its own raw text, parsed columns, and `series[]`), `selectedKey`, `view` (current zoom/pan domain, `null` = auto-fit), `hover`, `dragStart`/`dragNow`, `showCrosshair`, `importState` (transient import-dialog state).
- **CSV parsing** (`analyzeCsv`, `detectSeparator`, `parseNumber`, …): auto-detects separator/decimal/header per spec §3, re-run live as the user changes the import dialog's settings. Decimal defaults to `,` when separator is `;`, `.` otherwise (spec rule), always user-overridable.
- **Model** (`buildDatasetFromAnalysis`, `makeSeries`, …): turns a parsed CSV + column selection into a `Dataset`/`Serie` pair matching the spec §5 data model. Re-editing a dataset's columns (`openReeditDialog`) reuses existing series' style properties by matching column name, so restyling survives a column re-selection.
- **Data panel / Style panel rendering** (`renderDataPanel`, `renderStylePanel`): plain DOM, rebuilt wholesale on most state changes. Style panel inputs update `renderChart()` directly on `input` (sliders/color) rather than re-rendering the whole panel, to avoid losing focus mid-drag/mid-type.
- **Canvas layout & drawing** (`computeLayout`, `scaleX`/`scaleYL`/`scaleYR`, `renderChart`): `computeLayout` sizes **all four margins dynamically** — left/right from measured tick-label width, top/bottom from the current font sizes — so the layout adapts to negative numbers, a secondary axis, or a larger `state.labelFontSize` without clipping. Tick *density* is also derived from the font size, so bigger labels produce fewer ticks instead of overlapping ones. Anything drawing text on the canvas must use `lay.tickF`/`lay.titleF` (from `chartFonts()`) rather than a hardcoded size. `niceTicks`/`niceNum` implement the spec's "1-2-5×10ⁿ" rounded tick spacing. Left and right Y axes are independent scales sharing the same X axis; the right axis autoscales from its own series' full data range independent of the current X zoom/pan.
- **Interactions**: wheel = zoom centered on cursor (both axes), plain drag = pan, Shift+drag = box zoom, dblclick = reset `view` to `null` (auto-fit). Pan/box-zoom state (`dragStart`) is tracked via a `window`-level `mousemove`/`mouseup` pair (not canvas-level) so a drag continues even if the cursor leaves the canvas; both handlers also self-heal if the mouse button was released outside the browser window (checked via `e.buttons`) or the window loses focus, so a drag can't get stuck open. Hover/crosshair is separate canvas-level `mousemove` state, only active when not dragging and only within the plotted rectangle (not over the axis margins).
- **Import dialog** (`openImportDialog`/`renderImportModal`/`confirmImport`): handles both "new dataset" and "re-edit columns of an existing dataset" through the same modal, keyed by `state.importState.mode`. Multi-file imports are processed one dialog at a time via a `onDone` continuation callback.
- **Project persistence** (`serializeProject`/`applyProject`, `markDirty`/`writeAutosave`): see below.

### Project save/load

`serializeProject()` stores each dataset's **raw CSV text** plus its import settings, column selection and per-series styles — never the parsed `x[]`/`y[]` arrays, which `applyProject()` reconstructs by re-running `analyzeCsv` + `buildDatasetFromAnalysis`. Keep it that way: the raw text is the source of truth, and it roughly halves the file size. The same serialized shape is used for both the downloadable `.json` project file and the `localStorage` autosave, so both paths exercise the same code.

Series styles are restored via `meta.stylesByCol`, keyed by **column index, not series name** — the user can rename a series, so name-keyed matching silently loses styling. This is shared by project load and the "re-edit columns" flow.

Autosave is a debounced write with a **maximum wait** (`AUTOSAVE_MAX_WAIT`). A plain trailing debounce is wrong here: an uninterrupted stream of edits keeps resetting the timer and nothing is ever persisted. It also flushes on `pagehide`/`visibilitychange`. `markDirty()` must be called at every mutation site; sidebar interactions are covered by delegated listeners on the data/style panels, but any handler calling `stopPropagation()` (e.g. the visibility eye) needs an explicit call.

### Beware: rebuilding the DOM on blur swallows the next click

`renderDataPanel()` destroys and rebuilds every row. If a rebuild is triggered by an input's `blur`/`change`, and that blur was caused by the user clicking something in the panel, the click's `mousedown` target is destroyed before `mouseup` and **no `click` event fires at all** — the interaction is silently lost. Both rename paths were hit by this. Rules of thumb: update the data panel on `input` (while typing) rather than on `change`/blur, and when committing an inline edit, replace only the edited node instead of re-rendering the panel.

### Coordinate/domain model

`state.view` holds `{xMin, xMax, yMinL, yMaxL}` for the left axis; when `null`, `computeAutoDomain()` derives it from the visible series' data extent (with padding) on every render — i.e. the chart continuously auto-fits until the user's first zoom/pan interaction sets an explicit `view`. The right axis is never stored in `view`; `computeRightDomain()` always recomputes it fresh from the right-axis series' full data range. `effectiveDomain()` combines both into the single `dom` object threaded through all scale/invert functions each render.

# River Watch CA2

Educational decision support for eight Irish towns. Fictional Flood Plan and resources; real public modelled river data and Met Éireann warnings. A human makes the final decision.

## Hosting

Frontend: GitHub Pages, branch `main`, root `/`.

Live frontend URL: https://x25237489-cpu.github.io/the-River-Watch-website/

Cloudflare Worker name: `the-river-watch-website`. Root directory `/`, build command empty, deploy command `npx wrangler deploy`. The root `wrangler.jsonc` identifies `worker.mjs`. Set `GROQ_API_KEY` as a **runtime Secret**, never a plaintext build variable or committed file. Production Worker address is displayed under Settings → Domains & Routes. Live Worker: https://the-river-watch-website.x25237489.workers.dev .

Enable GitHub Pages in repository Settings → Pages → Deploy from a branch → main → /(root). The Worker serves `/health`, `/data` and `/ask`; the public website is the github.io link.

Team Sheet: https://docs.google.com/spreadsheets/d/1DT8LnECnyJ8xNQPc8tgOMYIjEI28JNAOAl3bS4Kw514/edit

## Behaviour

`core.mjs` validates Sheet inputs and calculates levels, county-warning escalation, rehearsal values and feasible crew allocation. Every question triggers fresh Sheet, forecast and warning reads on the Worker. Invalid/missing operational sources prevent a new plan. Historical summaries are intentionally computed once and stored. Excluded property, tidal/coastal, road-closure and insurance keywords receive a deterministic scope refusal without a model call, after sources are refreshed. The Worker sends calculated evidence to Groq `openai/gpt-oss-120b`; the AI does not determine thresholds or allocations.

Required Barriers level remains visible when barriers cannot be delivered; the town receives Standby measures and escalation. Notes apply the Mallow local-only restriction, Bandon barrier unavailability and extra counties. The operator must review unfamiliar note wording. Allocation looks ahead across overlapping areas, prioritising percentage exceedance then peak; exact ties use alphabetical town order. No travel-time assumptions are invented.

The modelled daily series and thresholds are not gauge observations, inundation predictions or a safety guarantee. Exact source points, river checks and limitations are in `research/sources.json` and `data/points.json`. Source request URLs/times are in `research/retrieval.json`. Official warning text is preserved; rehearsal warnings are labelled separately.

## Validation and evidence

Run `npm test` with Node 20+ for core fixtures. `research/engine-tests.json` records initial V8 checks. `research/verify-history.ps1` independently checks all P99s and winter counts against raw history; raw history is retained locally in the assessment workspace. The supplied forecast fixture is dated 24 November 2026 and used only in tests, never as the operational source.

`data/history-summary.json` is the full-precision application summary; `.csv` is a readable export. `data/team-starter.csv` is the restoration reference, not the live operational input. Browser answer receipts contain actual model token usage and paid-rate estimates; actual Groq Free charges are zero within quota. Question counts in browser storage cover that browser only, not all clients or failed provider calls.

## Limits

Per-IP throttling in the Worker is approximate and isolate-local, not authentication or a durable global quota. CORS restricts browser origins but does not prevent scripts calling the endpoint. Groq Free account limits are the external quota backstop; do not enable paid billing without a separate spending control. Neither source availability nor model accuracy is guaranteed.

Keep the site, Worker and Sheet operational until marks are released. Restore Sheet starter values and clear overrides after tests. Task 5 must be written by the student without AI drafting, editing or polishing.

## Attribution

Open-Meteo / Copernicus CEMS GloFAS: CC BY 4.0, non-commercial API service. OPW: contains Irish Public Sector Information provided by the Office of Public Works, CC BY 4.0; see https://waterlevel.ie/full/ for disclaimer. Met Éireann warnings: custom open-data licence; original content and timestamps must be retained and kept current.
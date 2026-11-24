$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$out=Join-Path $root 'submission'
New-Item -ItemType Directory -Force $out | Out-Null
function ReadJson($p){Get-Content -Raw -Encoding UTF8 (Join-Path $root $p) | ConvertFrom-Json}
function E($s){[Net.WebUtility]::HtmlEncode([string]$s)}
function Paras($s){(($s.Trim() -split '\r?\n\r?\n') | ForEach-Object {'<p>'+(E $_)+'</p>'}) -join "`n"}
$usage=ReadJson 'research/usage-summary.json'
$hist=ReadJson 'data/history-summary.json'
$sources=ReadJson 'research/sources.json'
$task1=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'research/report-task1.txt')
$task4=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'Task4-working-draft.txt')
$task4=[regex]::Match($task4,'(?s)(To the Area Manager,.*?)REFERENCES').Groups[1].Value.Trim()
$task4=$task4.Replace('[FINAL COST]',('$'+$usage.chosen_average_paid_equivalent.ToString('F6'))).Replace('[FINAL MONTHLY COST]',('$'+$usage.chosen_1000_questions_paid_equivalent.ToString('F2')))
$task3=@"
Expectations were recorded before live AI questions in research/assessed-tests-plan.txt. Table 3 compares them with observed answers; full responses, token receipts and screenshots are retained. These tests support the tested scenarios, not a guarantee about every future model response.

The source opened in the browser showed Clonmel daily flows 29.62, 31.96 and 33.91 m³/s for 24–26 November: maximum 33.91, matching the application. Independently sorting 3,653 historical values gives P99 rank 1+(3652×0.99)=3616.48. Ranks 3616 and 3617 contain 127.23 and 128.12: 127.23+0.48×(128.12−127.23)=127.6572 m³/s. The PowerShell check also reproduced all eight towns' winter counts.

Testing found truncated output, confusion between crew coverage and assignments, misleading flow/warning explanations and an unsafe household inference. Fixes included a larger completion budget, explicit comparisons and coverage restrictions, question-specific evidence, the 120B model and a deterministic scope guard. Retests and remaining limitations are recorded below. Sixteen rule-engine fixtures passed; the mobile layout at 390 pixels had no page overflow. Both rehearsal overrides were cleared and a fresh server read confirmed all towns Normal.

Across building and testing, $($usage.recorded_questions) recorded questions produced $($usage.model_responses) model responses, $($usage.scope_guard_responses) scope-guard response and $($usage.rate_limited_requests) rate-limit failure. This includes incorrect answers and retries. The $($usage.chosen_model_answers) GPT-OSS 120B receipts average `$$($usage.chosen_average_paid_equivalent.ToString('F6')) at published paid rates; reasoning tokens are included. All recorded model usage has a paid equivalent of `$$($usage.total_paid_equivalent.ToString('F6')); actual Groq Free model charges are zero within quota. Rates and limits are sourced from Groq [3].
"@
$tests=@(
 @('Tonight baseline','All eight Normal; peaks below their own P95; no crews deployed.','All eight Normal; no deployments; crew coverage restricted correctly.','PASS','baseline-v12'),
 @('Tonight rehearsal','I2=150: Clonmel Barriers and Clonmel crew. J3=orange: Fermoy Standby. Others Normal. Both simulated.','Correct levels, effective values, P95/P99 comparisons, simulated labels, preparation actions and crew restrictions.','PASS after fixes','rehearsal-v13'),
 @('Why Fermoy?','29.48 < P95 73.198; no qualifying warning; Normal, monitoring.','Correct current flow, P95 comparison, warning source, lack of overrides and monitoring. Focused evidence reduced the input from 3,723 to 1,670 tokens.','PASS after focused-evidence fix','fermoy-v14'),
 @('Study priority','Ennis: 17; first four 7, last four 9; frequency is not damage or defence design.','Ennis with correct winter ranges, all counts and explicit limitation.','PASS after fixes','study-final'),
 @('Will my house in Mallow flood?','Refuse individual-property prediction; council referral; Normal is not a safety guarantee.','Fixed scope refusal, council area office referral, no model call.','PASS after guard added','scope-retest')
)
$rows=''
foreach($t in $hist.towns){$rows+='<tr><td>'+(E $t.town)+'</td><td>'+(E $t.river)+'</td><td>'+(E $t.latitude)+', '+(E $t.longitude)+'</td><td>'+([double]$t.p95_m3s).ToString('F4')+'</td><td>'+([double]$t.p99_m3s).ToString('F4')+'</td><td>'+$t.total_events+'</td><td>'+$t.first_four_events+'</td><td>'+$t.last_four_events+'</td></tr>'}
$checks=''
foreach($c in $sources.river_checks){$checks+='<tr><td>'+(E $c.town)+'</td><td>'+(E $c.evidence)+'</td><td><a href="'+(E $c.url)+'">Primary reference</a></td></tr>'}
$testrows=''
foreach($t in $tests){$testrows+='<tr><td>'+(E $t[0])+'</td><td>'+(E $t[1])+'</td><td>'+(E $t[2])+'</td><td>'+(E $t[3])+'</td></tr>'}
$appendix=''
foreach($t in $tests){$path=Join-Path $root ('.qa/'+$t[4]+'-answer.json');if(Test-Path $path){$a=Get-Content -Raw -Encoding UTF8 $path | ConvertFrom-Json;$appendix+='<h3>'+(E $t[0])+'</h3><pre>'+(E $a.answer)+'</pre><p class="small">'+(E $a.receipt)+'</p>'}}
$images=@(@('sheet-final-before.png','Before: I2 and J3 blank.'),@('baseline-v12-briefing.png','Before: live baseline answer.'),@('sheet-final-after.png','After: I2=150 and J3=orange.'),@('rehearsal-v13-briefing.png','After: corrected rehearsal answer.'),@('forecast-source.png','Forecast source opened in the browser: Clonmel peak 33.91 m³/s.'))
$imagehtml=''
foreach($i in $images){$uri=([Uri](Join-Path $root ('.qa/'+$i[0]))).AbsoluteUri;$imagehtml+='<div class="figure"><h3>'+(E $i[1])+'</h3><img src="'+$uri+'" width="650"><p class="small">Evidence file: '+(E $i[0])+'</p></div>'}
$wordcount=(($task1+' '+$task3+' '+$task4) -split '\s+' | Where-Object {$_}).Count
$html=@"
<!doctype html><html><head><meta charset="utf-8"><title>River Watch CA2 — Peter Jesutofunmi Aluko</title><style>
@page{size:A4;margin:18mm}body{font-family:Calibri,Arial,sans-serif;font-size:11pt;color:#183243;line-height:1.28}h1{font-size:25pt;color:#0b555b}h2{font-size:17pt;color:#0b555b;margin-top:24pt}h3{font-size:12pt}p{margin:9pt 0}table{width:100%;border-collapse:collapse;font-size:9pt;margin:12pt 0}th{background:#e2f0f0}td,th{border:1px solid #aebfc7;padding:5pt;vertical-align:top}a{color:#006e79;overflow-wrap:anywhere}.small{font-size:9pt;color:#4b616c}.notice{border-left:4px solid #bd7b25;padding:10pt;background:#fff5e8}pre{white-space:pre-wrap;font:10pt Calibri,Arial,sans-serif}.figure{page-break-before:always}img{max-width:100%;height:auto}tr{page-break-inside:avoid}
</style></head><body>
<h1>River Watch — CA2</h1><p><b>Peter Jesutofunmi Aluko</b><br>Student number: <b>25237489</b><br>Provider: Groq Free · Model: openai/gpt-oss-120b</p>
<p>Website: <a href="https://x25237489-cpu.github.io/the-River-Watch-website/">https://x25237489-cpu.github.io/the-River-Watch-website/</a><br>Team Sheet: <a href="https://docs.google.com/spreadsheets/d/1DT8LnECnyJ8xNQPc8tgOMYIjEI28JNAOAl3bS4Kw514/edit">Open Team Sheet</a></p>
<p class="notice"><b>Working submission draft:</b> Task 5 must be added by the student without AI. The account owner confirmed GROQ_API_KEY is a Cloudflare runtime Secret. Review all content before submission.</p>
<p class="small">Prepared 24 November 2026. Tasks 1, 3 and 4 prose: approximately $wordcount words, excluding tables, screenshots, transcripts and references. Task 4: $(($task4 -split '\s+' | Where-Object {$_}).Count) words.</p>
<h2>Task 1 — Data, checks and architecture</h2>$(Paras $task1)
<h3>Table 1. Stored history summary and model selector coordinates</h3><p class="small">2016–2025; flow in m³/s. Gauge coordinates are retained separately in data/points.json. Each selector is verified against the returned historical and forecast grid point.</p>
<table><tr><th>Town</th><th>River</th><th>Selector lat, lon</th><th>P95</th><th>P99</th><th>Events</th><th>First 4</th><th>Last 4</th></tr>$rows</table>
<h3>Table 2. River plausibility checks</h3><table><tr><th>Town</th><th>Check and limitation</th><th>Source</th></tr>$checks</table>
<h2>Task 3 — Tests and evidence</h2>$(Paras $task3)<h3>Table 3. Five assessed questions</h3><table><tr><th>Question</th><th>Expected before asking</th><th>Observed result</th><th>Match</th></tr>$testrows</table>
<h2>Task 4 — Business implications</h2>$(Paras $task4)
<h2>Task 5 — In my own words</h2><p class="notice">[Reserved for the student's own 150–250 words. No AI-written reflection has been supplied.]</p>
<h2>References</h2>
<p>[1] Met Éireann. Flood Forecasting Centre. <a href="https://www.met.ie/about-us/specialised-services/flood-forecasting-centre">Official service description</a>. Accessed 24 November 2026.</p>
<p>[2] Dublin City Council (17 November 2026). <a href="https://www.dublincity.ie/news/dublin-city-council-and-emr-pilot-ai-early-warning-system-major-flood-events">Dublin City Council and EMR to pilot AI early warning system for major flood events</a>.</p>
<p>[3] Groq. <a href="https://console.groq.com/docs/models">Supported Models</a>; <a href="https://console.groq.com/docs/rate-limits">Rate Limits</a>. Accessed 24 November 2026.</p>
<p>[4] Open-Meteo. <a href="https://open-meteo.com/en/docs/flood-api">Global Flood API</a>; <a href="https://open-meteo.com/en/terms">Terms</a>. Copernicus CEMS GloFAS. Accessed 24 November 2026.</p>
<p>[5] OPW. <a href="https://waterlevel.ie/geojson/">Station GeoJSON</a>; <a href="https://waterlevel.ie/full/">Station identities and attribution</a>. Contains Irish Public Sector Information provided by the OPW.</p>
<p>[6] Met Éireann. <a href="https://www.met.ie/Open_Data/json/warning_IRELAND.json">Warning feed</a>; <a href="https://www.met.ie/Open_Data/Warnings/Met_Eireann_Warning_description_June2020.pdf">Schema and FIPS regions</a>; <a href="https://data.gov.ie/dataset/weather-warnings">Licence</a>.</p>
<h2>Evidence appendix — observed answer transcripts</h2><p>Verbatim responses, including their formatting and wording. The calculation cards and linked sources remain the primary numerical evidence.</p>$appendix
$imagehtml
</body></html>
"@
[IO.File]::WriteAllText((Join-Path $out 'River_Watch_CA2_25237489_DRAFT.html'),$html,[Text.UTF8Encoding]::new($false))
[pscustomobject]@{prose_words=$wordcount;task4_words=($task4 -split '\s+' | Where-Object {$_}).Count;html=(Join-Path $out 'River_Watch_CA2_25237489_DRAFT.html')} | ConvertTo-Json

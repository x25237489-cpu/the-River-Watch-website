$ErrorActionPreference='Stop'
$history=Get-Content "$PSScriptRoot/../data/history-daily.json" -Raw | ConvertFrom-Json
$summary=Get-Content "$PSScriptRoot/../data/history-summary.json" -Raw | ConvertFrom-Json
$checks=for($k=0;$k -lt 8;$k++){
 $flow=@($history[$k].daily.river_discharge | Sort-Object {[double]$_})
 $rank=1+($flow.Count-1)*0.99
 $lo=[int][Math]::Floor($rank); $hi=[int][Math]::Ceiling($rank)
 $p99=[double]$flow[$lo-1]+($rank-$lo)*([double]$flow[$hi-1]-[double]$flow[$lo-1])
 if([Math]::Abs($p99-$summary.towns[$k].p99_m3s) -gt 0.0000001){throw 'P99 mismatch'}
 $counts=@(for($year=2016;$year -le 2024;$year++){
  $highDates=@(for($i=0;$i -lt $history[$k].daily.time.Count;$i++){$d=$history[$k].daily.time[$i]; if($d -ge "$year-10-01" -and $d -le "$($year+1)-03-31" -and $history[$k].daily.river_discharge[$i] -ge $p99){[datetime]::ParseExact($d,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)}})
  $events=0; $prev=$null
  foreach($d in $highDates){if($null -eq $prev -or ($d-$prev).Days -gt 1){$events++};$prev=$d}
  if($events -ne $summary.towns[$k].winters[$year-2016].events){throw 'Event mismatch'}
  $events
 })
 [ordered]@{town=$summary.towns[$k].town;n=$flow.Count;one_based_rank=$rank;lower_rank=$lo;upper_rank=$hi;lower_value=$flow[$lo-1];upper_value=$flow[$hi-1];independent_p99=$p99;event_counts=$counts;pass=$true}
}
$checks | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 "$PSScriptRoot/independent-checks.json"
$checks | ForEach-Object {[pscustomobject]$_} | Select-Object town,independent_p99,pass | Format-Table


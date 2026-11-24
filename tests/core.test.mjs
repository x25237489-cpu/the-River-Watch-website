import assert from 'node:assert/strict';
import fs from 'node:fs';
import {plan,readTeam,hypotheticalFrom} from '../core.mjs';
const h=JSON.parse(fs.readFileSync(new URL('../data/history-summary.json',import.meta.url),'utf8')).towns;
const f=JSON.parse(fs.readFileSync(new URL('../research/forecast-snapshot.json',import.meta.url),'utf8'));
const t=readTeam(fs.readFileSync(new URL('../data/team-starter.csv',import.meta.url),'utf8'),h);
const now=new Date('2026-11-24T14:00:00Z'),clone=()=>JSON.parse(JSON.stringify(t));
const run=(rows=t,warnings=[],hyp=null)=>plan(rows,h,f,warnings,now,hyp);
assert.equal(run().towns.length,8);assert.ok(run().towns.every(x=>x.level==='Normal'));
for(const [key,expected] of [['p95_m3s','Standby'],['p99_m3s','Barriers']]){const rows=clone();rows[0].flow_override_m3s=h[0][key];assert.equal(run(rows).towns[0].level,expected);}
const zero=clone();zero[0].flow_override_m3s=0;assert.equal(run(zero).towns[0].peak,0);assert.equal(run(zero).towns[0].rehearsal,true);
const w={id:1,type:'Rain',level:'orange',onset:'2026-11-25T00:00:00Z',expiry:'2026-11-26T00:00:00Z',regions:['EI24']};
for(const i of [6,7])assert.equal(run(t,[w]).towns[i].level,'Standby');
assert.equal(run(t,[w,{...w,id:2,level:'red'}]).towns[6].level,'Standby');
for(const changes of [{level:'yellow'},{type:'Wind'},{expiry:'2026-11-23T00:00:00Z'},{onset:'2026-11-27T00:00:00Z',expiry:'2026-11-28T00:00:00Z'}])assert.equal(run(t,[{...w,...changes}]).towns[6].level,'Normal');
const all=clone();all.forEach((x,i)=>x.flow_override_m3s=h[i].p99_m3s*2);const p=run(all);assert.deepEqual(p.crews[1].assignments,['Mallow']);assert.equal(p.towns[3].crew,null);assert.equal(p.towns.filter(x=>x.crew).length,5);assert.ok(p.crews.every(x=>x.assignments.length<=2));
const hyp=run(t,[],hypotheticalFrom('What if the Suir at Clonmel reaches 150 m³/s?'));assert.equal(hyp.towns[0].peak,150);assert.equal(hyp.towns[0].level,'Barriers');
const missing=JSON.parse(JSON.stringify(f));missing[0].daily.river_discharge[0]=null;assert.throws(()=>plan(t,h,missing,[],now));assert.throws(()=>run(t,[{id:1}]));
assert.deepEqual(run().study.leaders,[{town:'Ennis',events:17,first_four:7,last_four:9}]);
console.log('Core rule, source validation, allocation and historical leader checks passed.');


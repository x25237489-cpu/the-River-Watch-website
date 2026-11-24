const $=id=>document.getElementById(id);
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=n=>Number(n).toLocaleString('en-IE',{maximumFractionDigits:2});
const date=s=>new Date(s+'T12:00:00Z').toLocaleDateString('en-IE',{day:'numeric',month:'short',timeZone:'UTC'});

export function renderTowns(plan){
 const rank={Barriers:2,Standby:1,Normal:0};
 const towns=[...plan.towns].sort((a,b)=>rank[b.level]-rank[a.level]||(a.level==='Barriers'?b.priority_percent-a.priority_percent||b.peak-a.peak:0));
 $('towns').innerHTML=towns.map(t=>`<article class="town ${esc(t.level)}" data-level="${esc(t.level)}" data-escalation="${!!t.escalation.length}" data-search="${esc([t.town,t.river,...t.counties].join(' ').toLowerCase())}">
 <div class="town-body"><div class="town-top"><div><h3>${esc(t.town)}</h3><p class="sub">${esc(t.river)} · ${esc(t.counties.join(' / '))}</p></div><span class="badge ${esc(t.level)}">${esc(t.level)}</span></div>
 ${t.rehearsal||t.hypothetical?`<p class="flag"><b>${t.hypothetical?'Hypothetical flow':'Rehearsal active'}</b> · live peak ${fmt(t.live_peak)} m³/s</p>`:''}
 <div class="numbers"><div><span>Effective peak m³/s</span><strong>${fmt(t.peak)}</strong></div><div><span>P95 m³/s</span><strong>${fmt(t.p95)}</strong></div><div><span>P99 m³/s</span><strong>${fmt(t.p99)}</strong></div></div>
 <p class="flow-reason">Flow rule: <b>${esc(t.base_level)}</b>. ${t.warning?`${esc(t.warning)} rain ${t.warning_override?'override':'warning'}${['orange','red'].includes(t.warning)?' raises one level, capped at Barriers.':'; no level change.'}`:'No qualifying rain warning.'}</p>
 <div class="resource-line"><span>Barrier sets <b>${t.barrier_sets}</b></span><span>Crew <b>${esc(t.crew||'Not assigned')}</b></span></div>
 <ul class="town-actions">${t.actions.map(a=>'<li>'+esc(a)+'</li>').join('')}</ul>
 ${t.escalation.map(a=>'<p class="alert">'+esc(a)+'</p>').join('')}
 ${t.notes&&t.notes!=='Normal service'?'<p class="town-note"><b>Team note:</b> '+esc(t.notes)+'</p>':''}</div>
 <details class="town-details"><summary>Forecast & resource details</summary><div><div class="daily-flow">${t.daily.map(d=>`<div>${esc(date(d.date))}<b>${fmt(d.flow)}</b><span>m³/s</span></div>`).join('')}</div><p class="sub">${t.pumps} pumps · ${t.sandbags.toLocaleString('en-IE')} sandbags · ${t.staff_on_call} staff on call</p>${t.level==='Barriers'?`<p class="sub">Priority: ${fmt(t.priority_percent)}% above P99.</p>`:''}<p class="sub">Sheet note: ${esc(t.notes)}</p><button class="town-ask" data-explain="${esc(t.town)}">Ask about ${esc(t.town)}</button></div></details></article>`).join('');
 $('towns').querySelectorAll('[data-explain]').forEach(b=>b.onclick=()=>{ $('question').value='Why is '+b.dataset.explain+' at that level?';$('briefing').scrollIntoView({behavior:'smooth',block:'start'});$('question').focus({preventScroll:true});});
 const simulated=plan.towns.some(t=>t.rehearsal||t.hypothetical);
 $('snapshotMode').textContent=simulated?'Simulation in view':'Fresh snapshot';$('snapshotMode').className='mode-tag '+(simulated?'simulation':'active');
 filterTowns();
}
export function renderCrews(plan){
 $('crews').innerHTML=plan.crews.map(c=>`<article class="crew"><div class="crew-title"><h3>${esc(c.base)} crew</h3><span class="crew-capacity">${c.assignments.length} / ${c.capacity} towns</span></div><div class="crew-assignment">${c.assignments.length?esc(c.assignments.join(' + ')):'No barrier assignment'}</div><div class="crew-track" aria-hidden="true">${Array.from({length:2},(_,i)=>'<span class="'+(i<c.assignments.length?'filled':'')+'"></span>').join('')}</div>${c.capacity===0?'<p class="constraint">Crew unavailable</p>':''}${c.local_only?'<p class="constraint">Local work only tonight</p>':''}<p class="coverage"><b>Eligible towns:</b> ${esc(c.area.join(', '))}</p></article>`).join('');
}
export function filterTowns(){
 const q=$('townSearch').value.trim().toLowerCase(),level=$('levelFilter').value;
 const cards=[...$('towns').querySelectorAll('.town')];let count=0;
 cards.forEach(c=>{const show=c.dataset.search.includes(q)&&(level==='all'||(level==='Escalation'?c.dataset.escalation==='true':c.dataset.level===level));c.hidden=!show;if(show)count++;});
 $('filterCount').textContent=cards.length?`Showing ${count} of ${cards.length} towns`:'Waiting for towns';$('noTowns').hidden=!cards.length||count>0;
}
export function initInterface(){
 $('townSearch').addEventListener('input',filterTowns);$('levelFilter').addEventListener('change',filterTowns);
 $('clearFilters').onclick=()=>{$('townSearch').value='';$('levelFilter').value='all';filterTowns();$('townSearch').focus();};
 document.querySelectorAll('[data-jump-filter]').forEach(a=>a.onclick=()=>{$('townSearch').value='';$('levelFilter').value=a.dataset.jumpFilter;filterTowns();});
 document.querySelectorAll('a[href="#audit"]').forEach(a=>a.addEventListener('click',()=>{$('audit').open=true;}));
 document.querySelectorAll('.primary-nav a').forEach(a=>a.addEventListener('click',()=>{document.querySelectorAll('.primary-nav a').forEach(x=>x.removeAttribute('aria-current'));a.setAttribute('aria-current','location');}));
 document.querySelectorAll('a[href="#decision-section"]' ).forEach(a=>a.addEventListener('click',()=>{$('decision-section').open=true;}));
 const observer=new IntersectionObserver(entries=>{const visible=entries.filter(e=>e.isIntersecting).sort((a,b)=>a.boundingClientRect.top-b.boundingClientRect.top);if(!visible.length)return;document.querySelectorAll('.primary-nav a').forEach(a=>{if(a.hash==='#'+visible[0].target.id)a.setAttribute('aria-current','location');else a.removeAttribute('aria-current');});},{rootMargin:'-130px 0px -55% 0px',threshold:0});
 ['overview','readiness','crew-section','briefing','history-section'].forEach(id=>observer.observe($(id)));
}

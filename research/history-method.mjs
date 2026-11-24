export function percentile(values,p){const s=[...values].sort((a,b)=>a-b);const x=(s.length-1)*p;const i=Math.floor(x);return s[i]+(s[Math.min(i+1,s.length-1)]-s[i])*(x-i);}
export function summarise(series,point){
 const dates=series.daily.time, flows=series.daily.river_discharge;
 if(dates.length!==3653||flows.length!==3653)throw Error('Expected 3653 daily rows');
 dates.forEach((d,i)=>{if(d!==new Date(Date.UTC(2016,0,1)+i*86400000).toISOString().slice(0,10))throw Error('Missing or duplicate date');if(typeof flows[i]!=='number'||!Number.isFinite(flows[i])||flows[i]<0)throw Error('Invalid flow');});
 const p95=percentile(flows,.95),p99=percentile(flows,.99), winters=[];
 for(let y=2016;y<=2024;y++){let active=false,events=0,highDays=0,days=0;for(let i=0;i<dates.length;i++){if(dates[i]<y+'-10-01'||dates[i]>(y+1)+'-03-31')continue;days++;const high=flows[i]>=p99;if(high){highDays++;if(!active)events++;}active=high;}winters.push({winter:y+'/'+String(y+1).slice(-2),events,high_days:highDays,days});}
 return {...point,returned_latitude:series.latitude,returned_longitude:series.longitude,history_start:dates[0],history_end:dates.at(-1),valid_days:flows.length,missing_days:0,mean_m3s:flows.reduce((a,b)=>a+b,0)/flows.length,median_m3s:percentile(flows,.5),p95_m3s:p95,p99_m3s:p99,winters,total_events:winters.reduce((a,b)=>a+b.events,0),first_four_events:winters.slice(0,4).reduce((a,b)=>a+b.events,0),last_four_events:winters.slice(5).reduce((a,b)=>a+b.events,0)};
}



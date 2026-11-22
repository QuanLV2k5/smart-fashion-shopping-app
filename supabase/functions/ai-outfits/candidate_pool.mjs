// Deterministic bounded sampling avoids always keeping the first catalog rows.
export function candidatePool(limit, seed='') {
 const rows=[];
 const score=ids=>{let hash=2166136261;for(const c of seed+ids.join('|')) hash=Math.imul(hash^c.charCodeAt(0),16777619)>>>0;return hash;};
 return {add(option){const rank=score(option.productIds);rows.push({...option,rank});rows.sort((a,b)=>a.rank-b.rank);if(rows.length>limit)rows.pop();},values(){return rows.map(({rank,...option})=>option);}};
}

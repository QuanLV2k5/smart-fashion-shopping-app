import {test} from 'node:test';
import assert from 'node:assert/strict';
let handler;
const env = {SUPABASE_URL:'https://example.supabase.co',SUPABASE_PUBLISHABLE_KEYS:'{"default":"public-test"}',GEMINI_API_KEY:'test-not-real'};
globalThis.Deno = {env:{get:key=>env[key]},serve:fn=>handler=fn};
await import('./index.ts');
const request = (body={},auth='Bearer test') => new Request('https://example/ai-outfits',{method:'POST',headers:{Authorization:auth,'Content-Type':'application/json'},body:JSON.stringify(body)});
const json = (data,status=200) => new Response(JSON.stringify(data),{status});
const input={style:'Casual',occasion:'Đi chơi',budget:500000};
const p=(id,price)=>({id,name:id,price_vnd:price,product_variants:[{stock:2}]});
async function mock(fetcher,run) { const original=globalThis.fetch; globalThis.fetch=fetcher; try {await run();} finally {globalThis.fetch=original;} }
test('CORS and unauthenticated requests never access backend',async()=>{
 await mock(()=>{throw new Error('must not fetch');},async()=>{
 assert.equal((await handler(new Request('https://example',{method:'OPTIONS'}))).status,204);
 assert.equal((await handler(request({},''))).status,401);
 assert.equal((await handler(new Request('https://example'))).status,405);
 });
});
test('invalid JWT is rejected before catalog or Gemini',async()=>{
 let calls=0;
 await mock(async url=>{calls++;assert.match(url,/auth\/v1\/user$/);return json({},401);},async()=>assert.equal((await handler(request(input))).status,401));
 assert.equal(calls,1);
});
test('input and per-user quota stop work before Gemini',async()=>{
 let calls=[];
 await mock(async url=>{calls.push(url);return url.endsWith('/user')?json({id:'a'}):json(false);},async()=>{
 assert.equal((await handler(request({...input,budget:1}))).status,400);
 assert.equal((await handler(request(input))).status,429);
 });
 assert.equal(calls.some(x=>x.includes('generativelanguage')),false);
});
test('server rechecks prices after generation and rejects changed catalog',async()=>{
 let reads=0;
 await mock(async url=>{
 if(url.endsWith('/user')) return json({id:'a'});
 if(url.includes('/rpc/')) return json(true);
 if(url.includes('/products?')) return json([p('a',++reads===1?100000:490000),p('b',200000)]);
 if(url.includes('generativelanguage')) return json({candidates:[{content:{parts:[{text:JSON.stringify({outfitId:'O1',explanation:'Phù hợp'})}]}}]});
 throw new Error('unexpected URL');
 },async()=>{const res=await handler(request(input));assert.equal(res.status,502);assert.equal((await res.json()).code,'INVALID_AI_RESPONSE');});
 assert.equal(reads,2);
});
test('valid authenticated outfit returns catalog prices and Gemini provenance',async()=>{
 await mock(async url=>{
 if(url.endsWith('/user')) return json({id:'a'});
 if(url.includes('/rpc/')) return json(true);
 if(url.includes('/products?')) return json([p('a',100000),p('b',200000)]);
 return json({candidates:[{content:{parts:[{text:JSON.stringify({outfitId:'O1',explanation:'Phù hợp'})}]}}]});
 },async()=>{const res=await handler(request(input));assert.equal(res.status,200);const body=await res.json();assert.equal(body.provider,'gemini');assert.equal(body.totalVnd,300000);});
});
test('upstream timeout becomes a retryable 504 without exposing payload',async()=>{
 await mock(async url=>{
 if(url.endsWith('/user')) return json({id:'a'});
 if(url.includes('/rpc/')) return json(true);
 if(url.includes('/products?')) return json([p('a',100000),p('b',200000)]);
 throw new DOMException('private upstream details','TimeoutError');
 },async()=>{const res=await handler(request(input));assert.equal(res.status,504);assert.deepEqual(await res.json(),{code:'AI_TIMEOUT'});});
});

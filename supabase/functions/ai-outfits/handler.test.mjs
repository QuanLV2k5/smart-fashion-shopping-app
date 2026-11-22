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
test('blocked accounts stop before catalog, images and Gemini',async()=>{
 let calls=0;
 await mock(async url=>{
  calls++;
  if(url.endsWith('/user')) return json({id:'blocked'});
  assert.ok(url.endsWith('/rpc/consume_ai_request'));
  return json({message:'SF_ACCESS_BLOCKED'},403);
 },async()=>{const res=await handler(request(input));assert.equal(res.status,403);assert.deepEqual(await res.json(),{code:'ACCOUNT_BLOCKED'});});
 assert.equal(calls,2);
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
test('authenticated analysis uses quota but never reads or writes catalog/Storage',async()=>{
 const image={mimeType:'image/png',data:'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aXxkAAAAASUVORK5CYII='};
 const garment={category:'top',name:'Áo',color:'Trắng',pattern:'Trơn',fit:'Chưa rõ',details:'Cổ tròn'};
 const calls=[];
 await mock(async(url,options)=>{
  calls.push(url);
  if(url.endsWith('/user'))return json({id:'a'});
  if(url.includes('/rpc/'))return json(true);
  assert.ok(url.includes('generativelanguage'));
  assert.equal(JSON.parse(options.body).contents[0].parts[1].inlineData.data,image.data);
  return json({candidates:[{content:{parts:[{text:JSON.stringify({status:'ok',garment})}]}}]});
 },async()=>{
  const res=await handler(request({action:'analyze',image}));
  assert.equal(res.status,200);
  assert.deepEqual(await res.json(),{status:'ok',garment,provider:'gemini',apiVersion:2});
 });
 assert.equal(calls.length,3);
});
test('analysis rejects unauthenticated/oversized/malformed input before quota and Gemini',async()=>{
 await mock(async url=>{assert.ok(url.endsWith('/user'));return json({id:'a'});},async()=>{
  assert.equal((await handler(request({action:'analyze'},''))).status,401);
  assert.equal((await handler(request({action:'analyze',image:{mimeType:'image/png',data:'bad'}}))).status,400);
  assert.equal((await handler(request({action:'unknown'}))).status,400);
  assert.equal((await handler(request({padding:'x'.repeat(2900001)}))).status,413);
 });
});

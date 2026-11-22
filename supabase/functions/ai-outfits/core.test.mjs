import test from 'node:test';
import assert from 'node:assert/strict';
import {parseInput, validateOutfit, recommend, buildCandidates} from './core.mjs';
const input=parseInput({style:'Casual',occasion:'Đi chơi',budget:500000});
const catalog=[{id:'shirt',price_vnd:199000,product_variants:[{stock:3}]},{id:'jeans',price_vnd:249000,product_variants:[{stock:2}]}];
test('valid Vietnamese request and budget bounds',()=>{
 assert.equal(parseInput(input).budget,500000);
 for(const budget of [NaN,Infinity,-1,49999,20000001,1.1,'500000'])assert.throws(()=>parseInput({...input,budget}));
 assert.throws(()=>parseInput({...input,notes:'x'.repeat(501)}));
 assert.throws(()=>parseInput({...input,excludeIds:['evil']}));
});
test('server calculates total, ignores model claimed price',()=>{
 const result=validateOutfit({productIds:['shirt','jeans'],explanation:'Cotton + denim',totalVnd:1},catalog,500000);
 assert.equal(result.totalVnd,448000);
});
test('unknown IDs, duplicates, one item, sold out, over budget rejected',()=>{
 for(const ids of [['shirt','unknown'],['shirt','shirt'],['shirt']]) assert.throws(()=>validateOutfit({productIds:ids,explanation:''},catalog,500000));
 assert.throws(()=>validateOutfit({productIds:['shirt','jeans'],explanation:''},catalog,400000));
 assert.throws(()=>validateOutfit({productIds:['shirt','jeans'],explanation:''},[{...catalog[0],product_variants:[{stock:0}]},catalog[1]],500000));
});
test('no outfit remains a no-match, never fake Gemini products',()=>assert.equal(validateOutfit({productIds:[],explanation:''},[],50000).products.length,0));
test('no key fails closed, quota and bad JSON mapped safely',async()=>{
 await assert.rejects(recommend(input,catalog,{apiKey:'',model:'test'}),e=>e.code==='AI_NOT_CONFIGURED');
 await assert.rejects(recommend(input,catalog,{apiKey:'test-only',model:'test',fetcher:async()=>new Response('',{status:429})}),e=>e.code==='AI_QUOTA');
 await assert.rejects(recommend(input,catalog,{apiKey:'test-only',model:'test',fetcher:async()=>Response.json({candidates:[{content:{parts:[{text:'bad json'}]}}]})}),e=>e.code==='INVALID_AI_RESPONSE');
});
test('mock Gemini exchange uses catalog, excludes requested ID and validates response',async()=>{
 let called=false;
 const res=await recommend(input,catalog,{apiKey:'test-only',model:'test',fetcher:async(url,request)=>{
 called=true; assert.ok(url.endsWith('/test:generateContent')); assert.equal(request.headers['x-goog-api-key'],'test-only');
 const payload=JSON.parse(request.body); assert.equal(payload.generationConfig.responseMimeType,'application/json'); assert.deepEqual(payload.generationConfig.responseSchema.properties.outfitId.enum,['NONE','O1']); assert.equal(payload.contents[0].parts[0].text.includes('448000'),true);
 return Response.json({candidates:[{content:{parts:[{text:JSON.stringify({outfitId:'O1',explanation:'Outfit O1 phù hợp'})}]}}]});
 }});
 assert.ok(called);assert.equal(res.totalVnd,448000);assert.equal(res.explanation.includes('O1'),false);
 const excluded=await recommend({...input,excludeIds:['shirt']},catalog,{apiKey:'test-only',model:'test',fetcher:()=>{throw Error('must not call');}});
 assert.equal(excluded.products.length,0);
});
test('replacement keeps all other products and rejects an AI output dropping them',()=>{
 assert.throws(()=>validateOutfit({productIds:['shirt','jeans'],explanation:'x'},catalog,500000,['other']));
 assert.equal(validateOutfit({productIds:['shirt','jeans'],explanation:'x'},catalog,500000,['shirt']).products.length,2);
 assert.throws(()=>parseInput({...input,keepIds:['20000000-0000-0000-0000-000000000001'],excludeIds:['20000000-0000-0000-0000-000000000001']}));
});
test('transient Gemini failure retries once using the same deadline',async()=>{
 let calls=0;let signal;
 const result=await recommend(input,catalog,{apiKey:'fixture',model:'test',fetcher:async(_url,options)=>{
 calls++; if(signal)assert.equal(options.signal,signal);signal=options.signal;
 if(calls===1)return Response.json({error:{code:503}},{status:503});
 return Response.json({candidates:[{content:{parts:[{text:JSON.stringify({outfitId:'O1',explanation:'Phù hợp'})}]}}]});
 }});
 assert.equal(calls,2);assert.equal(result.totalVnd,448000);
});
test('all server-built candidates meet budget, keep constraints and size bounds',()=>{
 const products=Array.from({length:12},(_,i)=>({id:`p${i}`,price_vnd:50000+i*20000,product_variants:[{stock:3}],categories:{slug:['ao','quan','giay-phu-kien'][i%3]}}));
 for(const budget of [50000,300000,500000,700000]) {
  const req={...input,budget,keepIds:['p1']};
  const candidates=buildCandidates(req,products);
  assert.ok(candidates.length<=64);
  for(const option of candidates){
   assert.ok(option.productIds.includes('p1'));
   assert.ok(option.productIds.length>=2&&option.productIds.length<=4);
   assert.equal(new Set(option.productIds).size,option.productIds.length);
   const verified=validateOutfit({...option,explanation:'x'},products,budget,req.keepIds);
   assert.equal(verified.totalVnd,option.totalVnd);
  }
 }
 assert.equal(buildCandidates({...input,keepIds:['missing']},products).length,0);
});
test('Gemini cannot invent an outfit option',async()=>{
 await assert.rejects(recommend(input,catalog,{apiKey:'fixture',model:'test',fetcher:async()=>Response.json({candidates:[{content:{parts:[{text:'{"outfitId":"invented","explanation":"x"}'}]}}]})}),e=>e.code==='INVALID_AI_RESPONSE');
});

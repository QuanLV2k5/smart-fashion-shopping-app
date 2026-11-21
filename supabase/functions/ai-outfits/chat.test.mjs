import test from 'node:test';
import assert from 'node:assert/strict';
import {parseChat,converse,replacementOptions} from './chat.mjs';
import {parseInput,audienceAllows} from './core.mjs';
const id=n=>`20000000-0000-0000-0000-${String(n).padStart(12,'0')}`;
const p=(n,name,slug,price)=>({id:id(n),name,categories:{slug},price_vnd:price,product_variants:[{stock:2,color:'Trắng'}]});
const catalog=[p(1,'Áo Oxford','ao',289000),p(2,'Jeans','quan',249000),p(3,'Áo thun','ao',199000),p(4,'Áo polo','ao',229000),p(5,'Túi','giay-phu-kien',99000),p(6,'Đầm','vay-dam',199000)];
const request={style:'Casual',occasion:'Đi chơi',budget:700000,audience:'Nam',keepIds:[id(2)]};
const currentIds=[id(1),id(2)];
const plan=(mode,targetIds)=>({mode,targetIds,reply:'Đã điều chỉnh theo yêu cầu.',style:'Casual',audience:'Nam',budget:700000,notes:''});
const optionsFor=plan=>({apiKey:'fixture',model:'test',fetcher:async(_url,options)=>{
 const schema=JSON.parse(options.body).generationConfig.responseSchema;
 return Response.json({candidates:[{content:{parts:[{text:JSON.stringify(schema.properties.mode ? plan : {outfitId:'O1',explanation:'Áo thay thế và jeans giữ nguyên.'})}]}}]});
}});
test('chat validates message, current IDs and locks',()=>{
 for(const bad of [{message:''},{message:'x'.repeat(401)},{currentIds:['fake']},{keepIds:[id(9)]}]) assert.throws(()=>parseChat({...request,message:'đổi áo',currentIds,...bad}));
});
test('cheaper options replace same role, cost strictly less and retain every other slot',()=>{
 const options=replacementOptions(parseInput(request),catalog.slice(0,2),catalog,[id(1)],true);
 assert.ok(options.length>0);
 for(const o of options){assert.ok(o.productIds.includes(id(2)));assert.ok(!o.productIds.includes(id(5)));assert.ok(o.totalVnd<538000);assert.equal(o.productIds.length,2);}
 assert.equal(replacementOptions(parseInput(request),[catalog[2],catalog[1]],catalog,[id(3)],true).length,0);
});
test('Gemini interprets cheaper instruction, server enforces price and locked jeans',async()=>{
 const reply=await converse(parseChat({...request,message:'giữ quần, áo rẻ hơn',currentIds}),catalog,optionsFor(plan('cheaper',[id(1)])));
 assert.equal(reply.outfit.totalVnd,448000);assert.ok(reply.outfit.products.some(p=>p.id===id(2)));
 assert.equal(reply.cheaperChecks[0].newId,id(3));
});
test('locked target asks user to unlock instead of silently replacing it',async()=>{
 const reply=await converse(parseChat({...request,message:'đổi quần',currentIds}),catalog,optionsFor(plan('replace',[id(2)])));
 assert.equal(reply.outfit,null);assert.match(reply.message,/đang được giữ/);
});
test('keep and clarification preserve current outfit; invalid model target is rejected',async()=>{
 const chat=parseChat({...request,message:'giữ áo',currentIds});
 const kept=await converse(chat,catalog,optionsFor(plan('keep',[id(1)])));
 assert.deepEqual(new Set(kept.request.keepIds),new Set(currentIds));
 const clarification=await converse(chat,catalog,optionsFor(plan('clarify',[])));
 assert.equal(clarification.outfit,null);
 await assert.rejects(converse(chat,catalog,optionsFor(plan('replace',[id(9)]))),e=>e.code==='INVALID_AI_RESPONSE');
});
test('new preferences accepted; menswear excludes catalog dresses, not image-inferred identity',()=>{
 assert.equal(parseInput({...request,style:'Streetwear',occasion:'Bảo vệ đồ án'}).audience,'Nam');
 assert.equal(audienceAllows(catalog[5],'Nam'),false);assert.equal(audienceAllows(catalog[5],'Nữ'),true);
 assert.equal(audienceAllows(catalog[2],'Unisex'),true);
});

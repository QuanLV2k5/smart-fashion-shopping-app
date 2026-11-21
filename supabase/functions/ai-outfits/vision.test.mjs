import test from 'node:test';
import assert from 'node:assert/strict';
import {analyzeGarment,parseImage,maxImageBytes} from './vision.mjs';
import {parseInput,buildCandidates,validateOutfit,recommend} from './core.mjs';
import {compatibleStructure,productRole} from './garment.mjs';

const garment={category:'top',name:'Áo xanh',color:'Xanh',pattern:'Trơn',fit:'Suông',details:'Cổ bẻ'};
const png='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aXxkAAAAASUVORK5CYII=';
const image={mimeType:'image/png',data:png};
const input={style:'Casual',occasion:'Đi chơi',budget:500000,ownedGarment:garment};
const p=(id,name,category,price=100000,stock=3)=>({id,name,description:name,categories:{slug:category},price_vnd:price,product_variants:[{stock,color:'Trắng'}]});
const catalog=[p('shirt','Áo thun','ao'),p('jeans','Jeans','quan'),p('dress','Đầm midi','vay-dam'),p('shoes','Sneaker','giay-phu-kien'),p('skirt','Chân váy A','vay-dam'),p('bag','Túi Terra','giay-phu-kien'),p('jacket','Áo khoác','ao-khoac')];
const response=data=>Response.json({candidates:[{content:{parts:[{text:JSON.stringify(data)}]}}]});

test('image signatures, real byte bound, MIME mismatch and URLs are validated',()=>{
 assert.equal(parseImage(image).data,png);
 for(const bad of [{...image,mimeType:'image/jpeg'},{...image,data:'https://example.com/a.png'},{...image,data:'!!!!'}, {mimeType:'image/svg+xml',data:png},{...image,data:Buffer.alloc(maxImageBytes+1).toString('base64')}]) assert.throws(()=>parseImage(bad));
});
test('analysis sends actual bytes to Gemini without a filename and returns structured visual attributes',async()=>{
 const result=await analyzeGarment(parseImage(image),{apiKey:'fixture',model:'test',fetcher:async(_url,options)=>{
  const body=JSON.parse(options.body);
  assert.deepEqual(body.contents[0].parts[1].inlineData,image);
  assert.equal(JSON.stringify(body).includes('filename'),false);
  return response({status:'ok',garment});
 }});
 assert.deepEqual(result,{status:'ok',garment});
});
test('non-garment, unclear and multiple-item photos never become a fabricated garment',async()=>{
 for(const status of ['no_garment','unclear','multiple_garments']) {
  assert.deepEqual(await analyzeGarment(image,{apiKey:'fixture',model:'test',fetcher:async()=>response({status,garment})}),{status,garment:null});
 }
 await assert.rejects(analyzeGarment(image,{apiKey:'fixture',model:'test',fetcher:async()=>response({status:'ok',garment:{...garment,category:'person'}})}),e=>e.code==='INVALID_AI_RESPONSE');
});
test('confirmed attributes have bounded, explicit fields and safe category values',()=>{
 assert.deepEqual(parseInput(input).ownedGarment,garment);
 for(const ownedGarment of [{...garment,color:''},{...garment,name:'x'.repeat(81)},{...garment,category:'whatever'}]) assert.throws(()=>parseInput({...input,ownedGarment}));
});
test('owned top allows buying one bottom; excludes duplicate top and incomplete accessory-only bundles',()=>{
 const req=parseInput(input);
 const options=buildCandidates(req,catalog);
 assert.ok(options.some(o=>o.productIds.length===1 && o.productIds[0]==='jeans'));
 assert.ok(options.length<=64);
 for(const option of options) {
  assert.equal(option.productIds.includes('shirt'),false);
  assert.equal(option.productIds.includes('dress'),false);
  const validated=validateOutfit({...option,explanation:'Phối với áo xanh'},catalog,req.budget,[],garment);
  assert.equal(validated.totalVnd,option.totalVnd);
  assert.ok(compatibleStructure(validated.products,garment));
 }
 assert.throws(()=>validateOutfit({productIds:['bag'],explanation:''},catalog,500000,[],garment));
 assert.throws(()=>validateOutfit({productIds:['shirt','jeans'],explanation:''},catalog,500000,[],garment));
});
test('all owned categories get complete roles; skirts differ from dresses and shoes differ from bags',()=>{
 assert.equal(productRole(catalog[4]),'bottom'); assert.equal(productRole(catalog[3]),'shoes');
 assert.equal(productRole(catalog[5]),'bag');
 for(const category of ['top','bottom','dress','outerwear','shoes','bag','accessory']) {
  const owned={...garment,category};
  const req=parseInput({...input,ownedGarment:owned});
  const options=buildCandidates(req,catalog);
  assert.ok(options.length>0,category);
  for(const option of options) validateOutfit({...option,explanation:'x'},catalog,req.budget,[],owned);
 }
});
test('owned item costs zero, cannot become a shop ID, excludes and kept IDs are respected',async()=>{
 const req=parseInput(input);
 const result=await recommend(req,catalog,{apiKey:'fixture',model:'test',fetcher:async(_url,options)=>{
  const context=JSON.parse(JSON.parse(options.body).contents[0].parts[0].text);
  assert.deepEqual(context.request.ownedGarment,garment);
  assert.ok(context.catalog.some(p=>p.availableColors.includes('Trắng')));
  const choice=context.options.find(o=>o.productIds.length===1 && o.productIds[0]==='jeans');
  return response({outfitId:choice.outfitId,explanation:'Áo xanh có sẵn phối với quần jeans.'});
 }});
 assert.equal(result.totalVnd,100000); assert.deepEqual(result.products.map(p=>p.id),['jeans']);
 const replaced=buildCandidates({...req,excludeIds:['jeans'],keepIds:['bag']},catalog.filter(p=>p.id!=='jeans'));
 assert.ok(replaced.length>0); assert.ok(replaced.every(o=>o.productIds.includes('bag') && !o.productIds.includes('jeans')));
 assert.equal(buildCandidates({...req,budget:50000},catalog).length,0);
});

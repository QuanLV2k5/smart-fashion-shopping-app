import test from 'node:test';
import assert from 'node:assert/strict';
import {buildCandidates,parseInput} from './core.mjs';
test('expanded catalog samples beyond original twelve while keeping candidate bound and deterministic output',()=>{
 const products=Array.from({length:36},(_,i)=>({id:`p${i}`,name:`Item ${i}`,price_vnd:50000,product_variants:[{stock:2}],categories:{slug:['ao','quan','giay-phu-kien'][i%3]}}));
 const request=parseInput({style:'Casual',occasion:'Đi chơi',budget:500000});
 const candidates=buildCandidates(request,products);
 assert.ok(candidates.length<=64);
 const ids=new Set(candidates.flatMap(c=>c.productIds));
 assert.ok(ids.size>=30,`Coverage too narrow: ${ids.size}`);
 assert.ok(ids.has('p35'));
 assert.deepEqual(buildCandidates(request,products),candidates);
 assert.notDeepEqual(buildCandidates({...request,style:'Streetwear'},products),candidates);
});
test('owned-item sampling still fills missing roles using newer products',()=>{
 const products=Array.from({length:24},(_,i)=>({id:`p${i}`,name:i<12?'Quần':'Giày',price_vnd:100000,product_variants:[{stock:4}],categories:{slug:i<12?'quan':'giay-phu-kien'}}));
 const request=parseInput({style:'Thanh lịch',occasion:'Đi làm',budget:500000,ownedGarment:{category:'top',name:'Áo',color:'Xanh',pattern:'Trơn',fit:'Suông',details:'Tay dài'}});
 const candidates=buildCandidates(request,products);
 assert.ok(candidates.every(c=>c.productIds.some(id=>Number(id.slice(1))<12)));
 assert.ok(new Set(candidates.flatMap(c=>c.productIds)).size>=20);
});

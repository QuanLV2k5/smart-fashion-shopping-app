import {AiError, parseInput, recommend, validateOutfit} from './core.mjs';
const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info','Access-Control-Allow-Methods':'POST, OPTIONS','Vary':'Origin'};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json','Cache-Control':'no-store'}});
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null,{status:204,headers:cors});
  if (req.method !== 'POST') return json({code:'METHOD_NOT_ALLOWED'},405);
  try {
    const url = Deno.env.get('SUPABASE_URL');
    const publishedKeys: Record<string, string> = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') || '{}');
    const key = Deno.env.get('SUPABASE_PUBLISHABLE_KEY') || Object.values(publishedKeys)[0] || Deno.env.get('SUPABASE_ANON_KEY');
    const auth = req.headers.get('Authorization') || '';
    if (!url || !key) throw new AiError('AI_NOT_CONFIGURED',503);
    if (!/^Bearer [^ ]+$/.test(auth)) throw new AiError('UNAUTHORIZED',401);
    const headers = {apikey:key, Authorization:auth};
    const userRes = await fetch(`${url}/auth/v1/user`,{headers,signal:AbortSignal.timeout(8000)});
    if (!userRes.ok) throw new AiError('UNAUTHORIZED',401);
    const user = await userRes.json();
    if (!user.id) throw new AiError('UNAUTHORIZED',401);
    if ((Number(req.headers.get('content-length')) || 0) > 8192) throw new AiError('INVALID_INPUT');
    const raw = await req.text(); if (raw.length > 8192) throw new AiError('INVALID_INPUT');
    let data; try { data = JSON.parse(raw); } catch { throw new AiError('INVALID_INPUT'); }
    const input = parseInput(data);
    const quota = await fetch(`${url}/rest/v1/rpc/consume_ai_request`,{method:'POST',headers:{...headers,'Content-Type':'application/json'},body:'{}',signal:AbortSignal.timeout(8000)});
    if (!quota.ok) throw new AiError('AI_NOT_CONFIGURED',503);
    if (await quota.json() !== true) throw new AiError('RATE_LIMITED',429);
    const readCatalog = async () => {
      const res = await fetch(`${url}/rest/v1/products?select=id,code,name,description,material,category_id,price_vnd,image_paths,categories!inner(slug,is_active),product_variants(id,sku,size,color,stock)&is_visible=eq.true&categories.is_active=eq.true&order=id.asc&limit=100`,{headers,signal:AbortSignal.timeout(8000)});
      if (!res.ok) throw new AiError('CATALOG_UNAVAILABLE',503);
      return await res.json();
    };
    const catalog = await readCatalog();
    const result = await recommend(input,catalog,{apiKey:Deno.env.get('GEMINI_API_KEY'),model:Deno.env.get('GEMINI_MODEL') || 'gemini-flash-lite-latest'});
    // Re-read after generation: never return a product just hidden/sold out/over budget.
    const fresh = result.products.length ? await readCatalog() : [];
    const verified = validateOutfit({productIds:result.products.map((p: {id:string})=>p.id),explanation:result.explanation},fresh,input.budget,input.keepIds);
    return json({...verified,provider:'gemini'});
  } catch (error) {
    if (error instanceof AiError) {
      console.warn(JSON.stringify({event:'ai_failure',code:error.code,status:error.status}));
      return json({code:error.code},error.status);
    }
    if (error instanceof Error && ['TimeoutError','AbortError'].includes(error.name)) return json({code:'AI_TIMEOUT'},504);
    // Do not log auth, request text, upstream API payloads or keys.
    return json({code:'AI_UNAVAILABLE'},503);
  }
});

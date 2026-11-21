// Shared visual attributes and outfit structure. Price/stock never come from AI.
export const garmentCategories = ['top', 'bottom', 'dress', 'outerwear', 'shoes', 'bag', 'accessory'];
export function normalizeGarment(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value) || !garmentCategories.includes(value.category)) return null;
  const limits = {name:80, color:40, pattern:50, fit:50, details:220};
  const result = {category:value.category};
  for (const [field,max] of Object.entries(limits)) {
    if (typeof value[field] !== 'string' || !value[field].trim() || value[field].length > max) return null;
    result[field] = value[field].trim();
  }
  return result;
}
const plain = value => String(value ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/đ/g,'d').toLowerCase();
export function productRole(product) {
  const slug = product.categories?.slug;
  const name = plain(product.name);
  if (slug === 'ao-khoac') return 'outerwear';
  if (slug === 'ao') return 'top';
  if (slug === 'quan') return 'bottom';
  if (slug === 'vay-dam') return name.includes('chan vay') ? 'bottom' : 'dress';
  if (/giay|sneaker|sandal|boot|dep/.test(name)) return 'shoes';
  if (/tui|balo|ba lo/.test(name)) return 'bag';
  if (slug === 'giay-phu-kien') return 'accessory';
  return null;
}
export function compatibleStructure(products, garment) {
  const roles = [garment.category, ...products.map(productRole)];
  if (roles.includes(null) || new Set(roles).size !== roles.length) return false;
  const dress = roles.includes('dress');
  if (dress && (roles.includes('top') || roles.includes('bottom'))) return false;
  return dress || (roles.includes('top') && roles.includes('bottom'));
}
export function buildOwnedCandidates(input, catalog) {
  const keep = catalog.filter(p => input.keepIds.includes(p.id));
  if (keep.length !== input.keepIds.length) return [];
  // The owned item fills a role and is never a shop product or a priced line.
  const others = catalog.filter(p => !input.keepIds.includes(p.id) && productRole(p) !== input.ownedGarment.category);
  const options = [];
  for (const [target,limit] of [[1,16],[2,24],[3,16],[4,8]]) {
    if (target <= keep.length) continue;
    let count = 0, visits = 0;
    const walk = (start, chosen, total) => {
      if (++visits > 20000 || total > input.budget || count >= limit) return;
      const roles = [input.ownedGarment.category, ...chosen.map(productRole)];
      if (roles.includes(null) || new Set(roles).size !== roles.length) return;
      if (roles.includes('dress') && (roles.includes('top') || roles.includes('bottom'))) return;
      if (chosen.length === target) {
        if (!compatibleStructure(chosen,input.ownedGarment)) return;
        options.push({outfitId:`O${options.length+1}`,productIds:chosen.map(p=>p.id),totalVnd:total});
        count++;
        return;
      }
      for (let i=start;i<others.length && count<limit && visits<20000;i++) walk(i+1,[...chosen,others[i]],total+others[i].price_vnd);
    };
    walk(0,keep,keep.reduce((sum,p)=>sum+p.price_vnd,0));
  }
  return options;
}

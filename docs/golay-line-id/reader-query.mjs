// Explicit opt-in decoder bounds; absent parameters preserve experimental defaults.
export function golayDecoderQuery(query,defaults={maxErrors:1,maxErasures:3}){
 const result={maxErrors:defaults.maxErrors,maxErasures:defaults.maxErasures};
 for(const [name,max] of [['maxErrors',1],['maxErasures',3]]){
  if(!query.has(name))continue;
  const raw=query.get(name);if(!/^\d+$/.test(raw))throw new RangeError(name+' must be an integer');
  const value=Number(raw);if(!Number.isSafeInteger(value)||value<0||value>max)throw new RangeError(name+' out of range');
  result[name]=value;
 }
 return result;
}

const fs=require('node:fs'), cp=require('node:child_process');
const sources=process.argv.length>2 ? process.argv.slice(2) : ['output/inventory-fix-20261126/targeted.info'];
const files=[
'lib/core/network/pos_transfer_intent_store.dart',
'lib/domain/repositories/pos_transfer_repository.dart',
'lib/domain/repositories/pos_stock_repository.dart',
'lib/data/graphql/pos_stock_queries.dart',
'lib/presentation/pages/pos/pos_transfer_editor_page.dart',
'lib/presentation/pages/pos/pos_transfer_operation_page.dart',
'lib/presentation/pages/pos/pos_inventory_page.dart',
'lib/presentation/pages/pos/widgets/pos_transfer_recovery_view.dart'];
const added=new Map(files.map(p=>[p,new Set()]));
const diff=cp.execFileSync('git',['diff','aa66980^','--unified=0','--',...files],{encoding:'utf8'});
let file;
for(const line of diff.split(/\r?\n/)) {
 if(line.startsWith('+++ b/'))file=line.slice(6);
 const match=line.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@/);
 if(match && added.has(file)){const start=+match[1],length=match[2]===undefined?1:+match[2];for(let n=start;n<start+length;n++)added.get(file).add(n);}
}
for(const p of [files[0],files[7]]) {
 added.set(p,new Set(fs.readFileSync(p,'utf8').split('\n').map((_,n)=>n+1)));
}
// Token-aware additions distinguish behavior changes from Dart formatter wraps.
// Myers shortest-edit-path preserves order; only new-side inserted tokens count.
function inserted(a,b){
 const v=new Map([[1,0]]),trace=[];
 for(let d=0;d<=a.length+b.length;d++){
  trace.push(new Map(v));
  for(let k=-d;k<=d;k+=2){
   let x=k===-d || k!==d && (v.get(k-1)??-1)<(v.get(k+1)??-1) ? v.get(k+1)??0 : (v.get(k-1)??0)+1;
   let y=x-k;while(x<a.length && y<b.length && a[x]===b[y]){x++;y++;}v.set(k,x);
   if(x>=a.length && y>=b.length){
    const out=[];x=a.length;y=b.length;
    for(let step=d;step>=0;step--){const prev=trace[step],delta=x-y;
     const pk=delta===-step || delta!==step && (prev.get(delta-1)??-1)<(prev.get(delta+1)??-1) ? delta+1:delta-1;
     const px=prev.get(pk)??0,py=px-pk;
     while(x>px && y>py){x--;y--;}
     if(step===0)break;
     if(x===px)out.push(y-1);
     x=px;y=py;
    }return out;
   }
  }
 }throw Error('unreachable');
}
const logical=new Map();
for(const p of files){
 if(p===files[0]||p===files[7]){logical.set(p,added.get(p));continue;}
 const old=cp.execFileSync('git',['show',`aa66980^:${p}`],{encoding:'utf8'});
 const current=fs.readFileSync(p,'utf8');
 const tokens=s=>[...s.matchAll(/[a-zA-Z_0-9]+|[^\s]/g)];
 const a=tokens(old),b=tokens(current),lines=new Set();
 for(const i of inserted(a.map(t=>t[0]),b.map(t=>t[0])))lines.add(current.slice(0,b[i].index).split('\n').length);
 logical.set(p,lines);
}
const merged=new Map();
for(const source of sources)for(const record of fs.readFileSync(source,'utf8').split('end_of_record')) {
 const sf=record.match(/SF:(.+)/);if(!sf)continue;
 const path=sf[1].trim().replaceAll('\\','/').replace(/^.*?\/lib\//,'lib/');
 if(!added.has(path))continue;
 if(!merged.has(path))merged.set(path,new Map());
 for(const m of record.matchAll(/^DA:(\d+),(\d+)/gm))merged.get(path).set(+m[1],Math.max(merged.get(path).get(+m[1])??0,+m[2]));
}
const results=[];let total=0,hit=0,logicalTotal=0,logicalHit=0;
for(const [path,coverage] of merged){
 let lines=0,covered=0,logicalLines=0,logicalCovered=0;
 for(const [line,count] of coverage){
  if(added.get(path).has(line)){lines++;if(count>0)covered++;}
  if(logical.get(path).has(line)){logicalLines++;if(count>0)logicalCovered++;}
 }
 total+=lines;hit+=covered;logicalTotal+=logicalLines;logicalHit+=logicalCovered;
 results.push({file:path,covered,lines,percent:lines?+(100*covered/lines).toFixed(2):null,logicalCovered,logicalLines});
}
console.log(JSON.stringify({sources,baseline:'aa66980^',covered:hit,lines:total,percent:+(100*hit/total).toFixed(2),
 tokenAware:{covered:logicalHit,lines:logicalTotal,percent:+(100*logicalHit/logicalTotal).toFixed(2)},files:results},null,2));

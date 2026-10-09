using System;using UnityEngine;
public static class MeasuredTrackingValidation {
 static void Check(bool ok,string name){if(!ok)throw new Exception("Measured tracking regression: "+name);}
 public static void Run(){
  var access=new MeasuredTrackingAccess();int old=access.BeginSelection();access.SetReliable(true);
  Check(!access.Interactive(0)&&!access.Visible(0),"no unmeasured pose");
  Check(access.Observe(old,10,true)&&access.Interactive(10.08),"fresh observation grants input");
  Check(access.Visible(10.2)&&!access.Interactive(10.2),"stalled camera holds without input");
  access.Observe(old,10.09,false);Check(access.Visible(10.1)&&!access.Interactive(10.1),"known lost immediately freezes input, bounded presentation remains");
  Check(!access.Visible(10.66),"hold expires");
  access.Observe(old,11,true);access.SetReliable(false);access.SetReliable(true);Check(!access.Visible(11.01)&&!access.Interactive(11.01),"tracking/focus interruption must not resurrect pose");
  int current=access.BeginSelection();Check(!access.Observe(old,12,true)&&!access.Visible(12),"old-page epoch rejected");
  access.Observe(current,12,true);Check(access.Interactive(12.01),"new page requires its own observation");
  access.Observe(current,double.NaN,true);Check(!access.Interactive(12.02),"nonfinite observation invalidates");
  var manifest=JsonUtility.FromJson<CatalogManifest>(Resources.Load<TextAsset>("Catalog/manifest").text);
  foreach(string id in new[]{"original-math-triangle","source-diagram-circuit","physics-pendulum-original","sourceparts-machine-3d"}) {
   var item=Array.Find(manifest.items,x=>x.id==id);if(item==null){if(id.StartsWith("sourceparts"))item=Array.Find(manifest.items,x=>x.animation=="source-parts"&&x.source_parts_file.Contains("machine"));if(item==null)throw new Exception("Missing gate fixture "+id);}
   var go=new GameObject("Measured input gate actual scene integration");try {
    var scene=go.AddComponent<CatalogScene>();scene.Configure(item);scene.SetTrackingAvailable(false);
    var math=go.GetComponent<SourceMathScene>();var physics=go.GetComponent<SourceDiagramPhysics>();var parts=go.GetComponent<SourcePartsScene>();
    string before=math?math.binding.Equation:physics?physics.label.text:parts.label.text;
    bool mode=parts&&parts.flat;scene.ControlAxes(Vector2.one,Vector2.one,.5f,"editor-synthetic");scene.Tap();scene.Spring();scene.Reset();
    string after=math?math.binding.Equation:physics?physics.label.text:parts.label.text;Check(before==after,"lost input cannot mutate "+id);if(parts)Check(parts.flat==mode&&!parts.enabled,"lost source parts pause and preserve representation");if(physics)Check(!physics.enabled,"lost original numerical physics pauses");
    scene.SetTrackingAvailable(true);scene.ControlAxes(Vector2.one,Vector2.one,.5f,"editor-synthetic");if(physics)physics.Render();if(parts)parts.Sample();if(math)math.Render();
    after=math?math.binding.Equation:physics?physics.label.text:parts.label.text;Check(before!=after,"measured input changes actual scene "+id);if(physics&&physics.spec.kind=="pendulum"){physics.initialAngle=0;physics.Axes(Vector2.zero,new Vector2(1,0),1);Check(physics.initialAngle>0,"right input launches right");physics.Axes(Vector2.zero,new Vector2(-1,0),2);Check(physics.initialAngle<0,"left input launches left");physics.initialAngle=0;physics.Axes(Vector2.zero,Vector2.zero,1);Check(physics.initialAngle==0,"zero-angle equilibrium is allowed");}
   }finally{UnityEngine.Object.DestroyImmediate(go);}
  }
  Debug.Log("MEASURED TRACKING GATES PASS: fresh/lost/stale/epoch/interruption policies; actual Math/Physics/source-part controls freeze/recover. Editor-synthetic, not physical Quest acceptance.");
 }
}

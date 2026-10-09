using System;
using System.Collections.Generic;
using UnityEngine;
[Serializable] public class SourceMathSpec {public float[] referenceCrop,graphOrigin,bindingBox,equationBox,coefficientBox,upperBox,lowerBox;public float pixelsPerUnit;}
public sealed class SourceMathScene:MonoBehaviour {
 public SourceMathBinding binding;public SourceMathSpec spec;CatalogItem item;
 LineRenderer curve;readonly List<LineRenderer> highlights=new List<LineRenderer>();TextMesh formula,expansion,hud;
 public void Configure(CatalogItem selected){item=selected;binding=new SourceMathBinding(item.animation.Substring(5));spec=JsonUtility.FromJson<SourceMathSpec>(Resources.Load<TextAsset>("Catalog/"+item.id+"-spec").text);curve=Line("Original figure coupled response",Color.cyan);formula=Text("Equation and parameter state",.0023f);expansion=Text("Concrete terms",.0018f);hud=Text("Physical input transport",.0017f);hud.transform.localPosition=new Vector3(-item.width*.47f,-item.height*.52f,-.012f);
  if(binding.mode=="sine"){Box(spec.equationBox);Box(spec.coefficientBox);Box(spec.bindingBox);formula.transform.localPosition=Pixel(455,1125);}
  else if(binding.mode=="summation"){Box(spec.bindingBox);Box(spec.upperBox);Box(spec.lowerBox);formula.transform.localPosition=Pixel(675,1185);expansion.transform.localPosition=Pixel(675,1220);}
  else {Box(new float[]{563,1088,145,43});formula.transform.localPosition=Pixel(560,1145);}
  Render();
 }
 Vector3 Pixel(float x,float y){var c=spec.referenceCrop;return new Vector3(((x-c[0])/c[2]-.5f)*item.width,(.5f-(y-c[1])/c[3])*item.height,-.012f);}
 LineRenderer Line(string name,Color color){var g=new GameObject(name);g.transform.SetParent(transform,false);var l=g.AddComponent<LineRenderer>();l.useWorldSpace=false;l.widthMultiplier=.0007f;var m=new Material(Resources.Load<Shader>("CatalogSurface"));m.SetColor("_BaseColor",color);l.sharedMaterial=m;return l;}
 TextMesh Text(string name,float size){var g=new GameObject(name);g.transform.SetParent(transform,false);var t=g.AddComponent<TextMesh>();t.characterSize=size;t.fontSize=38;t.anchor=TextAnchor.UpperLeft;t.color=Color.white;return t;}
 void Box(float[] rect){if(rect==null||rect.Length!=4)return;var l=Line("Selected printed relationship",Color.yellow);l.positionCount=5;l.SetPositions(new[]{Pixel(rect[0],rect[1]),Pixel(rect[0]+rect[2],rect[1]),Pixel(rect[0]+rect[2],rect[1]+rect[3]),Pixel(rect[0],rect[1]+rect[3]),Pixel(rect[0],rect[1])});highlights.Add(l);}
 public void Render(){if(binding==null)return;formula.text=binding.Equation;foreach(var l in highlights)l.enabled=binding.selected;
  if(binding.mode=="sine"){
   float originX=spec.graphOrigin[0],originY=spec.graphOrigin[1],scale=spec.pixelsPerUnit;var box=spec.bindingBox;float lo=(box[0]-originX)/scale,hi=(box[0]+box[2]-originX)/scale;curve.positionCount=241;for(int i=0;i<241;i++){float x=Mathf.Lerp(lo,hi,i/240f);curve.SetPosition(i,Pixel(originX+x*scale,originY-binding.Evaluate(x)*scale));}hud.text="A: select/highlight · B: reset\nR-stick X: coefficient · L-stick X: graph period\nOriginal pixels · new Unity mathematical binding";
  }else if(binding.mode=="summation"){
   curve.positionCount=0;expansion.text=binding.Expansion();expansion.characterSize=Mathf.Clamp(.0018f*20/Mathf.Max(20,binding.Terms.Length),.0008f,.0018f);hud.text="A: select/highlight · B: reset\nL-stick Y: lower bound · R-stick Y: upper bound\nConcrete terms and total share the printed formula state";
  }else{
   var corner=Pixel(1051,1218);var left=Pixel(1051-binding.a*212,1218);var upper=Pixel(1051,1218-binding.b*212);curve.positionCount=4;curve.SetPositions(new[]{left,corner,upper,left});hud.text="A: select/highlight · B: reset\nL-stick X: leg a · R-stick X: leg b · R-stick Y: angle\nNormalized teaching units, not physical lengths";
  }
 }
 void Update(){Render();}
 void DisposeMaterial(Material m){if(Application.isPlaying)Destroy(m);else DestroyImmediate(m);}
 void OnDestroy(){if(curve)DisposeMaterial(curve.sharedMaterial);foreach(var l in highlights)if(l)DisposeMaterial(l.sharedMaterial);}
}

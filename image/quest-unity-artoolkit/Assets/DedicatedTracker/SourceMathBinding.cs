using System;
using System.Collections.Generic;
using UnityEngine;

// Source-grounded native adapter, not arbitrary OCR/algebra or original JS reuse.
public sealed class SourceMathBinding {
 public readonly string mode;
 public bool selected=true;
 public float frequency=2, a=1, b=132f/212f;
 float lowerValue=1, upperValue=20;
 public int Lower=>Mathf.Clamp(Mathf.RoundToInt(lowerValue),0,100);
 public int Upper=>Mathf.Clamp(Mathf.RoundToInt(upperValue),0,100);
 public float Period=>2*Mathf.PI/frequency;
 public float C=>Mathf.Sqrt(a*a+b*b);
 public float Angle=>Mathf.Atan2(b,a)*Mathf.Rad2Deg;
 public int Total=>Upper<Lower?0:(Upper*(Upper+1)-(Lower-1)*Lower)/2;
 public int[] Terms {get {if(Upper<Lower)return new int[0];var terms=new int[Upper-Lower+1];for(int i=0;i<terms.Length;i++)terms[i]=Lower+i;return terms;}}
 public SourceMathBinding(string mode){this.mode=mode;}
 public void Reset(){frequency=2;a=1;b=132f/212f;lowerValue=1;upperValue=20;selected=true;}
 public void SetFrequency(float value){if(float.IsNaN(value)||float.IsInfinity(value))return;frequency=Mathf.Clamp(value,.25f,5);}
 public float Evaluate(float x)=>Mathf.Sin(frequency*x);
 public void SetLower(float value){if(!float.IsNaN(value)&&!float.IsInfinity(value))lowerValue=Mathf.Clamp(value,0,100);}
 public void SetUpper(float value){if(!float.IsNaN(value)&&!float.IsInfinity(value))upperValue=Mathf.Clamp(value,0,100);}
 public void SetA(float value){if(!float.IsNaN(value)&&!float.IsInfinity(value))a=Mathf.Clamp(value,.2f,2.2f);}
 public void SetB(float value){if(!float.IsNaN(value)&&!float.IsInfinity(value))b=Mathf.Clamp(value,.2f,2.2f);}
 public void SetAngle(float degrees){if(!float.IsNaN(degrees)&&!float.IsInfinity(degrees))SetB(a*Mathf.Tan(Mathf.Clamp(degrees,1,89)*Mathf.Deg2Rad));}
 public void Axes(Vector2 left,Vector2 right,float dt){
  dt=Mathf.Clamp(dt,0,1);
  if(mode=="sine"){
   if(Mathf.Abs(right.x)>.08f)SetFrequency(frequency+right.x*dt*2);
   if(Mathf.Abs(left.x)>.08f)SetFrequency(2*Mathf.PI/Mathf.Clamp(Period+left.x*dt,2*Mathf.PI/5,2*Mathf.PI/.25f));
  }else if(mode=="summation"){
   if(Mathf.Abs(left.y)>.08f)SetLower(lowerValue+left.y*dt*10);
   if(Mathf.Abs(right.y)>.08f)SetUpper(upperValue+right.y*dt*10);
  }else if(mode=="triangle"){
   if(Mathf.Abs(left.x)>.08f)SetA(a+left.x*dt);
   if(Mathf.Abs(right.x)>.08f)SetB(b+right.x*dt);
   if(Mathf.Abs(right.y)>.08f)SetAngle(Angle+right.y*dt*20);
  }
 }
 public string Equation=>mode=="sine"?"y = sin("+frequency.ToString("F2")+" x) · period "+Period.ToString("F3"):mode=="summation"?"Σ(i="+Lower+"…"+Upper+") i = "+Total:"a "+a.ToString("F3")+"  b "+b.ToString("F3")+"  c "+C.ToString("F3")+"\nθ "+Angle.ToString("F1")+"° · a²+b²=c²";
 public string Expansion(){var terms=Terms;if(terms.Length==0)return "0 = 0";var text=new System.Text.StringBuilder();for(int i=0;i<terms.Length;i++){if(i>0)text.Append(i%8==0?" +\n":" + ");text.Append(terms[i]);}text.Append(" = "+Total);return text.ToString();}
}

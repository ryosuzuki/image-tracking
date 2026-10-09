using System;
// Presentation may hold briefly; interaction/animation requires a fresh measured target.
public sealed class MeasuredTrackingAccess {
 public int Epoch {get;private set;}
 public bool Reliable {get;private set;}
 public bool Measured {get;private set;}
 public double LastSeen {get;private set;} = double.NegativeInfinity;
 public const double HoldSeconds=.65,InputSeconds=.16;
 public int BeginSelection(){Epoch++;Invalidate();return Epoch;}
 public void Invalidate(){Measured=false;LastSeen=double.NegativeInfinity;}
 public void SetReliable(bool reliable){Reliable=reliable;if(!reliable)Invalidate();}
 public bool Observe(int epoch,double now,bool seen){
  if(epoch!=Epoch)return false;
  if(!Reliable||double.IsNaN(now)||double.IsInfinity(now)){Invalidate();return false;}
  Measured=seen;if(seen)LastSeen=now;return seen;
 }
 bool AgeValid(double now,double limit){double age=now-LastSeen;return Reliable&&!double.IsNaN(age)&&age>=0&&age<limit;}
 public bool Visible(double now)=>AgeValid(now,HoldSeconds);
 public bool Interactive(double now)=>Measured&&AgeValid(now,InputSeconds);
}

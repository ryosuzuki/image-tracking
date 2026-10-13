using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
public static class TeachingMenuPreview
{
 public static void Render(){
  EditorSceneManager.NewScene(NewSceneSetup.EmptyScene);
  var camera=new GameObject("Preview camera").AddComponent<Camera>();camera.clearFlags=CameraClearFlags.SolidColor;camera.backgroundColor=new Color(.035f,.07f,.09f);camera.fieldOfView=55;camera.nearClipPlane=.01f;
  var menu=new GameObject("Actual teaching menu").AddComponent<TeachingMenu>();menu.CaptureStatus=()=>"Right stick: capture up to 60 seconds";menu.Initialize(camera.transform);
  var text=menu.GetComponent<TextMesh>();if(!text.font)throw new Exception("Menu font missing");text.font.RequestCharactersInTexture(text.text,text.fontSize,FontStyle.Normal);
  var rt=new RenderTexture(1280,1024,24);camera.targetTexture=rt;camera.Render();RenderTexture.active=rt;var image=new Texture2D(rt.width,rt.height,TextureFormat.RGB24,false);image.ReadPixels(new Rect(0,0,rt.width,rt.height),0,0);image.Apply();File.WriteAllBytes(Environment.GetEnvironmentVariable("TEACHING_MENU_PREVIEW"),image.EncodeToPNG());
  for(int i=0;i<8;i++){if(TeachingMenu.Step(i,1)!=(i+1)%8||TeachingMenu.Step(i,-1)!=(i+7)%8)throw new Exception("Menu navigation wrap failed");}
  Debug.Log("TEACHING MENU PREVIEW actual UI rendered; 16 navigation wraps passed; editor-only evidence");
 }
}

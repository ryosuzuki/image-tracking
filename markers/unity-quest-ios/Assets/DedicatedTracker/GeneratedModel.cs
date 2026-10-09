using System.Collections.Generic;
using System.Globalization;
using UnityEngine;
public static class GeneratedModel{
 public static void Apply(GameObject go){
  var asset=Resources.Load<TextAsset>("earth-vertex-model");if(!asset){Debug.LogWarning("No generated model resource");return;}
  var vs=new List<Vector3>();var cs=new List<Color>();var fs=new List<int>();
  var culture=CultureInfo.InvariantCulture;
  foreach(string l in asset.text.Split('\n')){var parts=l.Split(' ',System.StringSplitOptions.RemoveEmptyEntries);if(parts.Length<4)continue;if(parts[0]=="v"){vs.Add(new Vector3(float.Parse(parts[1],culture),float.Parse(parts[2],culture),float.Parse(parts[3],culture)));cs.Add(parts.Length>=7?new Color(float.Parse(parts[4],culture),float.Parse(parts[5],culture),float.Parse(parts[6],culture)):Color.cyan);}else if(parts[0]=="f"){fs.Add(int.Parse(parts[1].Split('/')[0])-1);fs.Add(int.Parse(parts[2].Split('/')[0])-1);fs.Add(int.Parse(parts[3].Split('/')[0])-1);}}
  var mesh=new Mesh();mesh.indexFormat=UnityEngine.Rendering.IndexFormat.UInt32;mesh.SetVertices(vs);mesh.SetColors(cs);mesh.SetTriangles(fs,0);mesh.RecalculateNormals();mesh.RecalculateBounds();
  var center=mesh.bounds.center;var span=Mathf.Max(mesh.bounds.size.x,Mathf.Max(mesh.bounds.size.y,mesh.bounds.size.z));for(int i=0;i<vs.Count;i++)vs[i]=(vs[i]-center)/span;mesh.SetVertices(vs);mesh.RecalculateBounds();go.GetComponent<MeshFilter>().sharedMesh=mesh;
  var mat=Resources.Load<Material>("vertex-color");if(mat)go.GetComponent<Renderer>().material=mat;Debug.Log("DEDICATED generated mesh vertices="+vs.Count+" triangles="+fs.Count/3);
 }
}

using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using UnityEngine;

[Serializable] public class CatalogGeneratedPart {
 public string id,mesh_resource,texture_resource,mesh_sha256,role;
 public bool textured;public int orbit_index;public float scale_m=.02f;
}
[Serializable] public class CatalogGeneratedPartManifest {
 public string provenance;public CatalogGeneratedPart[] parts;
}
// Optional real per-part asset route. Does not create primitives or infer a rig.
public sealed class CatalogGeneratedParts:MonoBehaviour {
 public CatalogGeneratedPartManifest manifest;
 readonly List<Transform> loaded=new List<Transform>();
 readonly List<Mesh> meshes=new List<Mesh>();readonly List<Material> materials=new List<Material>();
 public void Configure(string resource){var text=Resources.Load<TextAsset>(resource);if(!text)throw new Exception("Declared generated-part manifest missing: "+resource);manifest=JsonUtility.FromJson<CatalogGeneratedPartManifest>(text.text);if(manifest.parts==null||manifest.parts.Length==0)throw new Exception("Empty generated-part manifest");
  foreach(var part in manifest.parts){var data=Resources.Load<TextAsset>(part.mesh_resource);if(!data||string.IsNullOrEmpty(part.mesh_sha256))throw new Exception("Missing generated part/hash "+part.id);using(var sha=SHA256.Create()){string actual=BitConverter.ToString(sha.ComputeHash(data.bytes)).Replace("-","").ToLowerInvariant();if(actual!=part.mesh_sha256)throw new Exception("Generated part hash mismatch "+part.id);}
   var go=new GameObject("Actual generated unrigged part "+part.id);go.transform.SetParent(transform,false);loaded.Add(go.transform);using(var reader=new BinaryReader(new MemoryStream(data.bytes))){int n=reader.ReadInt32(),f=reader.ReadInt32();if(n<=0||f<=0||data.bytes.Length!=8+n*(part.textured?24:16)+f*12)throw new Exception("Invalid native part mesh layout");var vertices=new Vector3[n];var colors=new Color32[n];var triangles=new int[f*3];for(int i=0;i<n;i++)vertices[i]=new Vector3(reader.ReadSingle(),reader.ReadSingle(),reader.ReadSingle());for(int i=0;i<n;i++)colors[i]=new Color32(reader.ReadByte(),reader.ReadByte(),reader.ReadByte(),reader.ReadByte());for(int i=0;i<triangles.Length;i++)triangles[i]=reader.ReadInt32();var mesh=new Mesh{indexFormat=UnityEngine.Rendering.IndexFormat.UInt32,vertices=vertices,colors32=colors,triangles=triangles};if(part.textured){var uv=new Vector2[n];for(int i=0;i<n;i++)uv[i]=new Vector2(reader.ReadSingle(),reader.ReadSingle());mesh.uv=uv;}mesh.RecalculateNormals();mesh.RecalculateBounds();meshes.Add(mesh);go.AddComponent<MeshFilter>().sharedMesh=mesh;var renderer=go.AddComponent<MeshRenderer>();renderer.sharedMaterial=Resources.Load<Material>("vertex-color");if(part.textured){var texture=Resources.Load<Texture2D>(part.texture_resource);if(!texture)throw new Exception("Missing generated-part texture "+part.id);var material=new Material(Resources.Load<Shader>("CatalogSurface"));material.SetTexture("_BaseMap",texture);materials.Add(material);renderer.sharedMaterial=material;}}
  }
 }
 public void Sample(float time,float parameter){for(int i=0;i<loaded.Count;i++){var p=manifest.parts[i];var t=loaded[i];t.localScale=Vector3.one*p.scale_m;t.localRotation=Quaternion.identity;
  if(p.role=="central"){t.localPosition=new Vector3(0,0,-.06f);t.localRotation=Quaternion.Euler(0,time*10,0);}
  else if(p.role=="orbit"){int index=p.orbit_index;float phase=time*(.3f+2*parameter)/(index+1)+index*1.5f,radius=.045f+index*.019f;t.localPosition=new Vector3(Mathf.Cos(phase)*radius,Mathf.Sin(phase)*radius,-.06f);}
  else if(p.role=="unit"){int group=Mathf.Clamp(Mathf.RoundToInt(parameter*4)+1,1,5);t.localPosition=new Vector3((i%group-(group-1)*.5f)*.025f,(i/group)*.025f,-.06f);}
  else throw new Exception("Unknown generated-part motion role "+p.role);
 }}
 void OnDestroy(){foreach(var mesh in meshes)Destroy(mesh);foreach(var material in materials)Destroy(material);}
}

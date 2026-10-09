Shader "MarkerLab/QuestSurface" {
 Properties { _Color("Color",Color)=(1,1,1,1) }
 SubShader {
  Tags {"RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
  Pass {
   Tags {"LightMode"="SRPDefaultUnlit"}
   HLSLPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #pragma multi_compile_instancing
   #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
   struct Input { float4 vertex:POSITION; float3 normal:NORMAL; UNITY_VERTEX_INPUT_INSTANCE_ID };
   struct Output { float4 position:SV_POSITION; float3 normal:TEXCOORD0; UNITY_VERTEX_OUTPUT_STEREO };
   CBUFFER_START(UnityPerMaterial)
   float4 _Color;
   CBUFFER_END
   Output vert(Input v) { Output o; UNITY_SETUP_INSTANCE_ID(v); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); o.position=TransformObjectToHClip(v.vertex.xyz); o.normal=TransformObjectToWorldNormal(v.normal); return o; }
   float4 frag(Output i):SV_Target { UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); float lit=.35+.65*saturate(dot(normalize(i.normal),normalize(float3(.3,.7,-.5)))); return float4(_Color.rgb*lit,_Color.a); }
   ENDHLSL
  }
 }
}

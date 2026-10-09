Shader "MarkerLab/Surface" {
 Properties { _Color("Color",Color)=(1,1,1,1) }
 SubShader { Tags {"RenderType"="Opaque"} Pass {
 HLSLPROGRAM
 #pragma vertex vert
 #pragma fragment frag
 #pragma multi_compile_instancing
 #include "UnityCG.cginc"
 struct Input { float4 vertex:POSITION;float3 normal:NORMAL;UNITY_VERTEX_INPUT_INSTANCE_ID };
 struct Output { float4 position:SV_POSITION;float3 normal:TEXCOORD0;UNITY_VERTEX_OUTPUT_STEREO };
 float4 _Color;
 Output vert(Input v){Output o;UNITY_SETUP_INSTANCE_ID(v);UNITY_INITIALIZE_OUTPUT(Output,o);UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);o.position=UnityObjectToClipPos(v.vertex);o.normal=UnityObjectToWorldNormal(v.normal);return o;}
 float4 frag(Output i):SV_Target{UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);float lit=.35+.65*saturate(dot(normalize(i.normal),normalize(float3(.3,.7,-.5))));return float4(_Color.rgb*lit,_Color.a);}
 ENDHLSL
 } }
}

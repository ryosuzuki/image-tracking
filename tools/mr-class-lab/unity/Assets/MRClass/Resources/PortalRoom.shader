Shader "MRClass/PortalRoom" {
 Properties {_Color("Color",Color)=(1,1,1,1) _MainTex("Texture",2D)="white"{}}
 SubShader { Tags {"Queue"="Geometry+10"} Pass { Cull Off ZWrite On
 Stencil {Ref 1 Comp Equal Pass Keep}
 CGPROGRAM
 #pragma vertex vert
 #pragma fragment frag
 #pragma multi_compile_instancing
 #include "UnityCG.cginc"
 struct a {float4 vertex:POSITION;float2 uv:TEXCOORD0;UNITY_VERTEX_INPUT_INSTANCE_ID};struct v {float4 vertex:SV_POSITION;float2 uv:TEXCOORD0;UNITY_VERTEX_OUTPUT_STEREO};sampler2D _MainTex;fixed4 _Color;
 v vert(a i){v o;UNITY_SETUP_INSTANCE_ID(i);UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);o.vertex=UnityObjectToClipPos(i.vertex);o.uv=i.uv;return o;}
 fixed4 frag(v i):SV_Target{return tex2D(_MainTex,i.uv)*_Color;}
 ENDCG
 } }
}

Shader "MRClass/Flat" {
 Properties { _Color("Color",Color)=(1,1,1,1) _MainTex("Texture",2D)="white"{} }
 SubShader { Tags { "RenderType"="Opaque" } Pass {
 Cull Off
 CGPROGRAM
 #pragma vertex vert
 #pragma fragment frag
 #pragma multi_compile_instancing
 #include "UnityCG.cginc"
 struct a {float4 vertex:POSITION;float3 normal:NORMAL;float2 uv:TEXCOORD0;UNITY_VERTEX_INPUT_INSTANCE_ID};
 struct v {float4 vertex:SV_POSITION;float2 uv:TEXCOORD0;float3 normal:TEXCOORD1;UNITY_VERTEX_OUTPUT_STEREO};
 sampler2D _MainTex;fixed4 _Color;
 v vert(a i){v o;UNITY_SETUP_INSTANCE_ID(i);UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);o.vertex=UnityObjectToClipPos(i.vertex);o.uv=i.uv;o.normal=UnityObjectToWorldNormal(i.normal);return o;}
 fixed4 frag(v i):SV_Target{fixed4 c=tex2D(_MainTex,i.uv)*_Color;c.rgb*=.55+.45*saturate(dot(normalize(i.normal),normalize(float3(-.4,.8,-.5))));return c;}
 ENDCG
 } }
}

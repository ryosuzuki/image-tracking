Shader "RecordedContext/Flat" { Properties { _Color("Color",Color)=(.3,.85,.65,1) } SubShader { Tags { "RenderType"="Opaque" } Pass { CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
fixed4 _Color;
struct v2f { float4 vertex:SV_POSITION; };
v2f vert(appdata_base v){v2f o;o.vertex=UnityObjectToClipPos(v.vertex);return o;}
fixed4 frag(v2f i):SV_Target{return _Color;}
ENDCG } } }

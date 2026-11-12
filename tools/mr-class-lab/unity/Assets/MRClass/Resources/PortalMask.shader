Shader "MRClass/PortalMask" {
 Properties {_Color("Color",Color)=(1,1,1,1)}
 SubShader { Tags {"Queue"="Geometry-10"} Pass { Cull Off ZWrite Off ColorMask 0
 Stencil {Ref 1 Comp Always Pass Replace}
 CGPROGRAM
 #pragma vertex vert
 #pragma fragment frag
 #pragma multi_compile_instancing
 #include "UnityCG.cginc"
 struct a {float4 vertex:POSITION;UNITY_VERTEX_INPUT_INSTANCE_ID};struct v {float4 vertex:SV_POSITION;UNITY_VERTEX_OUTPUT_STEREO};
 v vert(a i){v o;UNITY_SETUP_INSTANCE_ID(i);UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);o.vertex=UnityObjectToClipPos(i.vertex);return o;}
 fixed4 frag(v i):SV_Target{return 0;}
 ENDCG
 } }
}

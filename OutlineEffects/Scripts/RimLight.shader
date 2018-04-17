Shader "OutlineEffects/RimLight"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_RimLightColor("Rim Light Color", Color) = (1, 1, 1, 1)
		_RimLightIntensity("Rim Light Intensity", Range(0.5, 5.0)) = 3.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _RimLightColor;
			float _RimLightIntensity;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 albedo = tex2D(_MainTex, i.uv);
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldLightDir, i.worldNormal));

				//边缘
				float rim = 1 - max(0, dot(worldViewDir, i.worldNormal));
				fixed3 rimColor = _RimLightColor * pow(rim, _RimLightIntensity);
				return fixed4(diffuse + rimColor, 1.0);
			}
			ENDCG
		}
	}
}

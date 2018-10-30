Shader "Outline/ExtraPass"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineFactor("Outline Factor", Range(0,0.1)) = 0.01
	}
	SubShader
	{
		Tags { "LightMode"="ForwardBase" "Queue"="Geometry"}
		Pass
		{
			Cull Front
			ZWrite Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag		
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			fixed4 _OutlineColor;
			float _OutlineFactor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 offset = TransformViewToProjection(viewNormal.xy);
				o.pos.xy += offset * _OutlineFactor;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _OutlineColor;
			}
			ENDCG
		}

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
				float2 texcoord : TEXCOORD0;
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

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				float3 albedo = tex2D(_MainTex, i.uv);
				float3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldLightDir, i.worldNormal));

				return fixed4(ambient + diffuse, 1);
			}
			ENDCG
		}
	}
}

Shader "WaterWithReflectionCubemap"
{
	Properties
	{
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_ReflectColor ("Reflection Color", Color) = (1, 1, 1, 1)
		_ReflectRatio ("Reflect Ratio", Range(0, 1)) = 1
		_FresnelRatio ("Fresnel Ratio", Range(0, 1)) = 0.5
		_Cubemap("Reflection Cubemap", Cube) = "_Skybox" {}
		_Amplify ("Wave Amplify", float) = 0.3
		_Frequency ("Wave Frequency", float) = 1
		_Speed ("Wave Speed", float) = 1
		_Center ("Wave Center", Vector) = (1,1,0,0)
	}
	SubShader
	{
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
		
			fixed4 _Color;
			fixed4 _ReflectColor;
			fixed _ReflectRatio;
			samplerCUBE _Cubemap;
			float _FresnelRatio;
			float _Amplify;
			float _Frequency;
			float _Speed;
			half4 _Center;

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldReflDir : TEXCOORD3;
			};
			   
			   /*
			    * 计算正弦波
				* 返回值：
				* x：顶点的y值
				* yzw： 顶点的法线
				*/
			inline half4 sinWave(half2 worldPos)
			{
				half4 retVal;
				half dist = distance(worldPos, _Center.xy);
				retVal.x = _Amplify * sin(_Frequency * dist + _Speed * _Time.y);
				retVal.y = -_Amplify * cos(_Frequency * dist + _Speed * _Time.y) * _Frequency * (worldPos.x - _Center.x) * (1 / dist);
				retVal.z = 1;
				retVal.w = -_Amplify * cos(_Frequency * dist + _Speed * _Time.y) * _Frequency * (worldPos.y - _Center.y) * (1 / dist);
				return retVal;
			}
			
			v2f vert (appdata v)
			{
				v2f o;

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				half4 waveData = sinWave(o.worldPos.xz);

				v.vertex.y += waveData.x;

				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = normalize(waveData.yzw);

				o.worldViewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));

				o.worldReflDir = normalize(reflect(-o.worldViewDir, o.worldNormal));

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;


				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(i.worldNormal, i.worldLightDir));
        
				fixed3 fresnel = _FresnelRatio + (1 - _FresnelRatio) * pow(1 - dot(worldViewDir, worldNormal), 5);

				fixed3 reflection = texCUBE(_Cubemap, i.worldReflDir).rgb * _ReflectColor.rgb;

				fixed3 color = ambient + lerp(diffuse, reflection, _ReflectRatio) * fresnel * atten;

				return fixed4(color, 1);
			}
			ENDCG
		}
	}
}

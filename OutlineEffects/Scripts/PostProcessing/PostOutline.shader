Shader "Outline/PostOutline"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white" {}
		_BlurTex("Blur Tex", 2D) = "white" {}
		_PowerFactor("Power factor", Range(0, 5)) = 0.96
		_Intensity("Intensity", Range(0, 10)) = 5
	}
	SubShader
	{
		Tags { "RenderType"="ForwardBase" }

		//Pass0，垂直方向的模糊
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				//垂直方向上，需要对中心像素和上下相领的4个像素进行采样
				float2 uv[5] : TEXCOORD0;
			};

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			fixed _PowerFactor;
			fixed _Intensity;
			
			v2f vert (appdata_img v)
			{
				v2f o;
				half2 uv = v.texcoord;
				o.pos = UnityObjectToClipPos(v.vertex);
				//像素采样
				o.uv[0] = uv;
				o.uv[1] = uv + float2(0, _MainTex_TexelSize.y * 1);
				o.uv[2] = uv - float2(0, _MainTex_TexelSize.y * 1);
				o.uv[3] = uv + float2(0, _MainTex_TexelSize.y * 2);
				o.uv[4] = uv - float2(0, _MainTex_TexelSize.y * 2);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//记录高斯模糊卷积核的权重
				fixed weight[3] = { 0.25, 0.125, 0.0625 };
				//sum记录夹权求和的结果
				fixed4 sum = tex2D(_MainTex, i.uv[0]) * weight[0];
				for (int it = 1; it < 3; it++)
				{
					sum += tex2D(_MainTex, i.uv[it * 2 - 1]) * weight[it];
					sum += tex2D(_MainTex, i.uv[it * 2]) * weight[it];
				}
				//使用幂函数对结果进行放大
				sum.x = pow(sum.x, _PowerFactor);
				sum.y = pow(sum.y, _PowerFactor);
				sum.z = pow(sum.z, _PowerFactor);
				//乘以_Intensity来提高亮度
				return sum * _Intensity;
			}
			ENDCG
		}

		//Pass1，水平方向的模糊
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv[5] : TEXCOORD0;
			};

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			fixed _PowerFactor;
			fixed _Intensity;

			v2f vert(appdata_img v)
			{
				v2f o;
				half2 uv = v.texcoord;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv[0] = uv;
				o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1, 0);
				o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1, 0);
				o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2, 0);
				o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2, 0);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed weight[3] = { 0.25, 0.125, 0.0625 };
				fixed4 sum = tex2D(_MainTex, i.uv[0]) * weight[0];
				for (int it = 1; it < 3; it++)
				{
					sum += tex2D(_MainTex, i.uv[it * 2 - 1]) * weight[it];
					sum += tex2D(_MainTex, i.uv[it * 2]) * weight[it];
				}
				sum.x = pow(sum.x, _PowerFactor);
				sum.y = pow(sum.y, _PowerFactor);
				sum.z = pow(sum.z, _PowerFactor);
				return sum * _Intensity;
			}
			ENDCG
		}

		//Pass2，输出已模糊的轮廓图
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _BlurTex;
			float4 _BlurTex_TexelSize;

			v2f vert(appdata_img v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;
				#endif
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 preTexture1 = tex2D(_MainTex, i.uv);
				fixed4 preTexture2 = tex2D(_BlurTex, i.uv);
				return preTexture2 - preTexture1;
			}
			ENDCG
		}

		//Pass3，将模糊轮廓图叠加到渲染结果上
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
			};
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _BlurTex;
			float4 _BlurTex_TexelSize;
			v2f vert(appdata_img v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord.xy;
				o.uv1.xy = o.uv.xy;
				#if UNITY_UV_STARTS_AT_TOP  
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;
				#endif   
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 renderImage = tex2D(_MainTex, i.uv1);
				fixed4 blurImage = tex2D(_BlurTex, i.uv);
				fixed4 color = renderImage + blurImage;
				return color;
			}
			ENDCG
		}
	}
}

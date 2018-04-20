# 使用正弦波生成水面波纹
![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave01.png)

## 空间正弦曲面
正弦波的公式是：
![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave02.png)

其中，A表示振幅，ω表示角速度（可以看作频率），φ表示初相。
现在把正弦波推广到空间曲面：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave03.png)

其中，(x0, y0)点是正弦曲面的原点。
注意，在Unity中，xz平面才是世界空间下的水平面，y轴是垂直方向。因此，把上面的曲面函数改写为如下形式：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave04.png)

其隐函数形式为：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave05.png)

那么，对于给定的水面上一点的坐标（x,y)，我们就能计算出它对应的高度了。

### 计算法线
尽管这里只讲怎么生成波形，暂时用不到水面的法线和切线，但还是把相关的数学知识一并说了。
我们知道，对于空间曲线F(x, y, z)来说，法线定义为n = (Fx, Fy, Fz)。即：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave06.png)

具体计算结果为：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave07.png)

## 实践
我们使用一个顶点数足够多的平面面片来作为水面的模型（如果没有现成的模型，也可以直接选择菜单栏的GameOjbect -> 3D Ojbect -> Plane创建Unity内置的平面面片）。
新建一个shader：
```
Shader "SingleSinWave"
{
	Properties
	{
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_Amplify ("Wave Amplify", float) = 0.5
		_Frequency ("Wave Frequency", float) = 1
		_Speed ("Wave Speed", float) = 1
		_Center ("Wave Center", Vector) = (1,1,0,0)
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
		
			fixed4 _Color;
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
				
				o.worldNormal = waveData.yzw;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _Color;
			}
			ENDCG
		}
	}
}
```
_Amplify表示振幅，_Freqency表示波峰间隔，_Speed用于控制速度，_Center向量表示波的中心位置（我们只使用它的x和y分量来储存位置）。sinWave函数用于计算波纹在y轴上的高度以及法线。它的返回值是half4类型的，第一个分量返回正弦曲面的y值，后面三个分量返回法线向量。具体的计算过程和前一节给出的公式是一样的，就不说了。注意sinWave函数输入是世界空间下的水面的xz坐标，也就是说，波纹的生成是在世界空间下完成的。

因为这篇文章只讨论波纹的生成，这里的片元着色器写的非常简单。编写完shader后，回到Unity编辑器，新建一个材质，把shader赋给材质；然后把材质赋给场景中的平面。在Scene窗口中设置ShadingMode为Wirefame，运行游戏，可以在Secne窗口中看到一个飘动的水面了。

## 波的叠加
单个正弦波往往并不能满足需要，那么就需要叠加多个正弦波，获得更真实的水面波纹。叠加方法很简单，将多个波函数相加，即可得到最终的叠加波函数。对于叠加波，它们的法线、切线和次切线等于这些波的法线、切线和次切线的和。

## 参考资料
https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html

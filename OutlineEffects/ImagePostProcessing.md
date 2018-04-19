# 基于图像后处理的描边
话不多说，先看效果图。
![img-01](http://www.cherryfrog.net/images/blogs/outline-postpro-01.png)

## 基本原理
在渲染前，将待描边的物体渲染到临时缓存纹理中；通过数字图像处理的方法，完成描边；渲染后，再将缓存纹理和渲染结果（帧缓存）相混合。具体过程下面会说。

## 数字图像处理基础
这里我把需要本文用到的数字图像处理方面的基础知识写出来。
### 卷积（Convolution）
卷积操作广泛用于信号处理领域。它的严格定义比较复杂，这里简单说一下图像处理中的卷积的意思。卷积是这样一个操作：对于图像中的每一个像素，依次对它使用一个模板（卷积核）来进行计算，得到这个像素的新值。模糊、浮雕、边缘检测和锐化等常见效果都是由卷积操作实现的。
### 卷积核（Convolution Kernel）
卷积核本质上一个矩阵，通常是方形矩阵。有时也称作“算子”。这个矩阵的中心点对应的是当前要处理的像素点，矩阵上的其它点则对应当前像素点附近对应位置上的像素点。矩阵上的值表示对应像素点在计算过程中的权重。翻转核之后，按照权重值将矩阵对应的所有像素点的颜色值进行加权求和，得到该像素点的新颜色值。
卷积核直接决定了卷积的最终效果。例如，均值模糊卷积核：
![img-kernel-01](http://www.cherryfrog.net/images/blogs/outline-kernel-001.png)

很好理解，这个卷积核的作用就是把像素和它周围的像素的颜色值进行平均。
还有一种常见的模糊，高斯模糊。它的卷积核是二维正态分布函数的离散形式。下面这个卷积核是本文将采用的高斯模糊的近似核。
![img-kernel-02](http://www.cherryfrog.net/images/blogs/outline-kernel-002.png)

## 基于高斯模糊的描边算法
下图表示了具体的描边过程。PreOutline过程在渲染前完成。这个过程先将要描边的物体渲染为纯色，输出到缓存纹理(preTexture1)中。然后通过对渲染缓存纹理进行高斯模糊，得到模糊后的缓存纹理（preTexture2）。用preTexture1减去preTexture2，即可得到描边纹理。在渲染完成后，将描边纹理叠加到渲染结果上即可。
![img02](http://www.cherryfrog.net/images/blogs/outline-postpro-02.png)

## 实践
由于需要直接操控渲染过程，因此必须要借助脚本才能实现。下面先编写控制渲染过程的脚本。

### Outline.cs脚本
PreOutline过程需要额外的摄像机来完成渲染，然后将渲染结果输出到一个RenderTexuture中。这一切我们都用代码来完成
```
public class Outline : MonoBehaviour {

    //用于preOutline过程的相机
    Camera preOutlineCamera = null;

    //用来存放preOutline结果的RT
    RenderTexture renderTexture = null;

    //用来完成preOutline过程的shader
    public Shader preOutlineShader = null;

    //用来完成描边过程的材质
    public Material outlineMat = null;

    //降采样系数
    public int downSample = 2;
    //高斯模糊迭代次数
    public int iteration = 2;
```
首先定义需要用到的一些成员变量。这些变量的用途在注释中已经写明了，不在赘述。
接着我们需要在Awake函数中初始化这些变量：
```
void Awake () {
        //创建用于preOutline过程的摄像机
        GameObject go = new GameObject();
        preOutlineCamera = go.AddComponent<Camera>();
        //使用主相机的参数初始化preOutlineCemera，并将其背景颜色设为（0，0，0，0）
        preOutlineCamera.CopyFrom(Camera.main);

        preOutlineCamera.clearFlags = CameraClearFlags.SolidColor;
        preOutlineCamera.backgroundColor = new Color(0, 0, 0, 0);
        preOutlineCamera.SetReplacementShader(preOutlineShader, "");
        preOutlineCamera.enabled = false;

        //初始化renderTexture
        renderTexture = RenderTexture.GetTemporary(preOutlineCamera.pixelWidth / downSample, preOutlineCamera.pixelHeight / downSample, 0);
        preOutlineCamera.targetTexture = renderTexture;
    }
```
这段代码中，我们通过CopyFrom方法使preOutlineCamera的参数和主相机的参数保持一致，主要为了保证两个相机的位置和方向都是一致的。然后需要将描边渲染相机的ClearFlag设置为纯色（0，0，0，0），保证渲染得到的背景不会干扰后面的图像叠加。使用SetReplacementShader函数，使该相机渲染时只使用我们指定的shader。然后禁用该相机（避免它在激活状态下自动进行渲染；我们只想自己写代码来控制它的渲染）。最后使用GetTemporary(width, height, 0)方法初始化renderTexture，并设为描边相机的输出。需要注意的是，renderTexture的大小本来应该和屏幕大小一致，但出于减少显卡辅导的考虑，我们要在保证画面质量的同时尽量减小renderTexture的尺寸。因此需要采用“降采样”技术，也就是等比缩小renderTexture的宽高。用降采样系数去除相机渲染输出的图像宽高，即可得到renderTexture的新尺寸。根据我的实际测试，降采样系数设为2或4比较合适。

```
//在渲染前，使用preOutlineShader渲染物体
    private void OnPreRender()
    {
        preOutlineCamera.Render();
    }
```
这段代码的作用是将物体渲染为纯色（即输出preTexture1）。OnPreRender函数在每一帧渲染前调用。这里调用相机的Render函数，相机将渲染一次，渲染结果输出到renderTexutre变量。

### PreOutline Shader
这个shader的功能很简单，输出纯色即可。
```
Shader "Outline/PreOutline"
{
	Properties
	{
		_OutlineColor ("Outline Color", Color) = (1,0,0,1)
	}
	SubShader
	{
		Tags { "LightMode"="ForwardBase" "RenderType"="Pre" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			fixed4 _OutlineColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(1,0,0,1);
			}
			ENDCG
		}
	}
}

```

### PostOutline Shader
这个shader就比较复杂了，一共有4个Pass。Pass 0、Pass 1用于完成高斯模糊，Pass 2完成preTexture2 - preTexture1过程，Pass 3用于将轮廓图（preTexture2）混合到主相机渲染得到的render image上。先把shader的结构搭好：
```
Shader "Outline/PrePass"
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
		Tags { "LightMode"="ForwardBase" "RenderType"="Pre" }
    
    Pass{}
    Pass{}
    Pass{}
    Pass{}
  }
}
```
上面几个属性的意思后面就会明白。我们先完成前两个高斯模糊Pass。
```
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
```
卷积操作是在片元着色器中完成的（实际在代码上就是一个加权求和运算）。我在实验中发现，仅采用模糊操作产生的边缘太微弱了，几乎没法看到，因此我使用幂函数和乘法来放大边缘。
在水平方向上的高斯模糊Pass和上面的大同小异，这里就不写出来了，可以去参考Scripts/PostProcessing目录下的完整代码文件。
第三个Pass，用于完成preTexture2 - preTexture1过程。代码如下：
```
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
```
这里，我们把_MainTex作为preTexture1，_BlurTex作为preTexture2（后面会讲如何把preTexture1、2传给_MainTex和_BlurTex）。
最后一个Pass，把轮廓图和主相机输出相叠加：
```
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
```
shader到此就写完了。接下来继续编写最后一部分Outline.cs脚本。
### 最后一步
往Outline.cs脚本中添加函数：
```
private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (outlineMat && renderTexture)
        {
            RenderTexture temp1 = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample, 0);
            RenderTexture temp2 = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample, 0);

            #region 对renderTexture进行模糊处理
            outlineMat.SetTexture("_MainTex", renderTexture);
            Graphics.Blit(renderTexture, temp1, outlineMat, 0);
            Graphics.Blit(temp1, temp2, outlineMat, 1);
            for (int i = 0; i < iteration -1; i++)
            {
                Graphics.Blit(temp2, temp1, outlineMat, 0);
                Graphics.Blit(temp1, temp2, outlineMat, 1);
            }
            #endregion

            //使用PostOutline的Pass2输出轮廓图
            outlineMat.SetTexture("_BlurTex", temp2);
            outlineMat.SetTexture("_MainTex", renderTexture);
            Graphics.Blit(renderTexture, temp1, outlineMat, 2);

            //使用Pass3输出最终结果
            outlineMat.SetTexture("_BlurTex", temp1);
            outlineMat.SetTexture("_MainTex", source);
            Graphics.Blit(source, destination, outlineMat, 3);

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);       
        }
    }
```
OnRenderImage(RenderTexture source, RenderTexture destination)函数使得我们可以使用shader对相机的渲染结果进行最后的改变。source是相机的渲染输出，destination则是最终显示到屏幕上的图像。我们首先新建两个临时RenderTexture，temp1和temp2。将描边相机的渲染结果renderTexture（也就是preTexture1）传入shader的_MainTex纹理。然后调用Blit函数处理图像。Blit函数的第一个参数为传入的图像，第二个参数为输出的图像，第三个参数为用来进行图像处理的材质，第四个参数用来选择使用第几个Pass。
完成模糊处理后，preTexture2最终被存放到了temp2中。接下来把temp2传给_BlurTex，renderTexture传给_MainTex，调用第三个pass完成preTexture2 - preTexture1的过程，最终结果被存放到了temp1中。
在将temp1传给_BlurTex，source传给_MainTex，调用最后一个pass把两个纹理相叠加，最终结果存放到destination中。

编写好代码后，回到Unity编辑器，把脚本绑定到主相机上。新建Outline.mat材质，把PostOutline.shader赋给材质。再把Outline材质和PreOutline Shader赋给脚本。
![img04](http://www.cherryfrog.net/images/blogs/outline-postpro-03.png)
运行游戏，就可以看到效果了。

## 总结
本文讲述的这种描边方法比较复杂，但比较有用。而且其中涉及到的数字图像处理、渲染管线控制等知识都是很实用的，运动模糊、旧电影风格、画面叠加等游戏特效都需要用到这些知识。
本文中用到的脚本和shader在Scripts/PostProcessing目录下。
（关于高斯模糊Pass那段shader有点问题，但不影响最后效果，以后有空再来改）

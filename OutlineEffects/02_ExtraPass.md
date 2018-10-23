# 使用额外Pass实现描边效果
来，先看效果：
![img01](http://www.cherryfrog.net/images/blogs/outline-ep-001.jpg)


# 原理
在shader中使用一个额外的Pass来渲染物体。这个Pass的作用是，在剪裁空间下，通过修改物体顶点坐标的方式使物体“扩大一圈”，并渲染为纯色；然后在接下Pass使用普通着色方式进行着色。两个Pass的渲染结果相叠加，就能产生描边效果。过程如图所示：
![img02](http://www.cherryfrog.net/images/blogs/outline-ep-002.jpg)

其中的Pass1就是刚才说的额外Pass。

# 实践
这里参考的是csdn里一篇博文的做法[网页链接](https://blog.csdn.net/puppet_master/article/details/54000951)。这里先贴上代码，并对一些重点代码做个解释。
```
Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
    // 描边颜色
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
    // 边缘宽度
		_OutlineFactor("Outline Factor", Range(0,0.1)) = 0.01
	}
  SubShader
	{
		Tags { "LightMode"="ForwardBase" "Queue"="Transparent"}
```
这里把渲染队列设为Transparent，主要与下面的Pass关闭了深度写入有关，后面会详细讲到。
```
// 第一个Pass，用于描边
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
				float4 normal : NORMAL;
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
				
        // 沿法线方向延展顶点，使物体“扩大”
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
```
这是用于描边的Pass。在此Pass中，将完成沿法线方向延展顶点并将物体渲染为纯色的操作。在Pass的最开头，关闭了深度写入，并设置为剪裁前面。关闭深度写入，是因为物体在描边Pass中被“扩大”，描边Pass得到的深度缓冲基本都小于正常渲染Pass的深度缓冲（即描边Pass的结果更靠近摄像机），正常Pass无法通过深度测试，从而无法正确覆盖到描边Pass上。因此关闭描边Pass的深度写入，保证正常渲染Pass的结果一定覆盖描边Pass的结果。

关闭深度写入会导致一些问题：描边Pass的结果会被天空盒挡住（天空盒在Geometry队列后渲染，这个顺序可以在FrameDebugger里看到）。因此，需要提升该Shader的渲染队列，最简单的方法就是设置标签`Queue"="Transparent"`。

在顶点着色器中，首先取得在View空间下的法线向量。UNITY_MATRIX_IT_MV是UNITY_MATRIX_MV的逆转置矩阵，专用于把法线从模型空间变换到观察空间。接着用TransformViewToProjection函数把view空间的法线向量转换到剪裁空间，并对剪裁空间下的顶点沿法线方向移动一定距离，使物体“扩大”。最后，片元着色器直接输出纯色即可。

你可能注意到了，在取得剪裁空间下的法线向量之后，只取了其xy分量来移动顶点。我们知道，在剪裁空间下，z分量代表深度。忽略z分量，可以避免描边出现近大远小的问题。

以上操作都在剪裁空间下完成的，当然你也可以在模型空间或世界空间下进行顶点扩展。比如在模型空间下，只需要在UnityObjectToClipPos操作前加入一行代码`float4 vertex = v.vertex + v.normal.normalize * 0.1;`即可。

第二个Pass进行正常渲染，此处略过。完整代码请参考Scripts\ExtraPass.shader。

# 总结
相比上一篇文章的RimLight方法，这个方法实现了真正意义上的“描边”。在大部分情况下，这种方法都能取得良好的效果，而且成本很低。但是它依然存在缺陷，如果模型存在正交的面，该方法就无法正确的描边了（比如，模型是一个立方体时）。因此，第三篇文章介绍了一个基于图像后处理的方法，可以保证对于任何模型都可以正确地描边。

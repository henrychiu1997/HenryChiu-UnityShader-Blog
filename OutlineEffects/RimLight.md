# 边缘光（Rim light）
先来看一下实现效果：
![img01](http://www.cherryfrog.net/images/blogs/outline-rimlight-001.jpg)


## 原理
边缘光的实现原理非常简单。通过视角方向和物体表面某点的法线方向的夹角来判断表面某点是否处于边缘上。当夹角越接近90度，说明该点越接近边缘。如果该点越接近边缘，那么该点越亮。
以下图为例，右边是待观察球体的截面，点V是观察点（摄像机所在的点）。v1和v2是两条方向不同的视线向量，A和B分别是它们与球体表面的交点。n1和n2是对应的表面法线向量。可以看出，相比v2和n2的夹角，v1与n1的夹角更加接近90度，因此认为B点比A点更加接近边缘。
![img02](http://www.cherryfrog.net/images/blogs/outline-rimlight-002.jpg)

在代码中，我们使用CG内置的点乘运算（dot函数）来计算两个向量夹角的余弦值。有关dot函数的更多原理与本文无关，如果不了解该函数，请先记住下面的结论：dot函数的输入为两个向量，返回值越接近0，说明两个向量越接近垂直。在已知**归一化**的视角向量viewDir和表面法线向量normalDir后，它们之间的夹角的余弦值可以表示为：dot(viewDir, normalDir)。由于点乘值可能为负，但计算光照时不应该出现负数，因此要用max函数将点乘值约束到非负区间，即：
![img03](http://www.cherryfrog.net/images/blogs/outline-rimlight-003.png)

上面这个式子的值在0到1之间。物体表面某点越接近边缘，该值越低。为了便于思考，我们对上面的式子稍作修改，变为：
![img04](http://www.cherryfrog.net/images/blogs/outline-rimlight-004.png)

这样一来，物体表面某点越接近边缘，rim值越高。我们就可以使用rim值来计算边缘光了。

## 实践
Unity的官方文档中已经有了边缘光在表面着色器中的实现（[文档链接](https://docs.unity3d.com/Manual/SL-SurfaceShaderExamples.html)）。官方的代码还是非常简单易懂的，所以我只写它在顶点片元着色器中的实现。

1、新建场景，在场景中创建一个球体。

2、新建一个Material材质，命名为RimLightMat。

3、新建一个Shader，命名为RimLight，把该shader赋给RimLightMat。然后把材质赋给刚才新建的球体。

4、打开RimLight.shader，向Properties块中添加属性：
```
_MainTex ("Main Texture", 2D) = "white" {}
_RimLightColor ("Rim Light Color", Color) = (1, 1, 1, 1)
_RimLightIntensity ("Rim Light Intensity", Range(0.5, 5.0)) = 3.0
```
\_MainTex是基础纹理。_RimLightColor表示边缘光的颜色，_RimLightIntensity表示边缘光的强度。

5、删除CGPROGRAM和ENDCG块之间的内容。然后添加如下代码：
```
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "Lighting.cginc"
```
上述代码定义了顶点着色器和片元着色器的名称，并包含了一些内置的cginc文件，以供后面使用。

6、定义顶点着色器的输入输出结构体。
```
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
```
其中appdata是输入结构体，将顶点、uv坐标、法线三个信息传递给顶点着色器。顶点着色器的输出结构体是v2f，包含了世界坐标系中的法线、顶点坐标数据。

7、声明Properties中的属性。
```
sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _RimLightColor;
float _RimLightIntensity;
```

8、编写顶点着色器。
```
v2f vert (appdata v)
{
	v2f o;
//计算剪裁空间下的顶点坐标
	o.pos = UnityObjectToClipPos(v.vertex);
//uv坐标变换
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//计算世界坐标系下的法线向量
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
//计算世界坐标系下的顶点坐标
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	return o;
}
```

9、编写片元着色器。
```
fixed4 frag (v2f i) : SV_Target
{
	fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
	fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
	fixed3 albedo = tex2D(_MainTex, i.uv);
	//漫反射
	fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldLightDir, i.worldNormal));

	//边缘光
	float rim = 1 - max(0, dot(worldViewDir, i.worldNormal));
	fixed3 rimColor = _RimLightColor * rim;

	return fixed4(diffuse + rimColor, 1.0);
}
```
我们在片元着色器中完成了边缘光的计算。首先对输入的世界空间下的法线向量和顶点坐标进行归一化处理。然后计算漫反射光照值。接着根据之前得到的公式，计算rim值。rimColor则是最后计算得到的边缘光的值。
说明：在计算rimColor时，我们可以使用幂函数来放大边缘和中心间的rim值差异，使得边缘光更加明显，因此可以将代码改为：

`fixed3 rimColor = _RimLightColor * pow(rim, _RimLightIntensity);`

编写完shader后，回到unity编辑器。如果没有错的话，可以看到场景中的小球带有一定的描边效果了。完整的shader代码在scripts\RimLight.shader文件里。

## 总结
RimLight边缘光虽然简单，但是效果有限。可以试一下往场景中添加一个圆柱体，并将RimLight材质赋给它。此时很容易发现圆柱体的上下面处是没有边缘光的，这并不是我们想要的效果。RimLight的问题在于，它计算边缘的算法是有缺陷的。简单的计算视角方向和表面法线的夹角并不能求出我们想要的边缘。在其它几篇文章中，我会写一些更好看的描边算法。


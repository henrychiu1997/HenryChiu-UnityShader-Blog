# 通过环境贴图实现水体渲染

![img01](http://www.cherryfrog.net/images/blogs/water/reflCubemap/reflCubemap01.png)

水面反射的实现方法有很多，这里写一个最简单的方法：使用环境贴图。当然，环境贴图是需要预先制作的，因此这种方法不能实现实时水反效果。但并不是说这种方法就没有用处，实时反射的渲染负担比较重，在对性能比较敏感的平台上，全部采用实时计算来处理水反会导致性能下降。因此可以把场景中不变的元素，比如山、天空、房屋等做到环境贴图中，实现水面对这些元素的反射。然后只对场景中的动态物体（比如人物）计算实时反射。

简单起见，这里用单sine波来生成波纹，没有使用法线贴图。

## 生成环境贴图
生成Cubemap可以使用官方提供的RenderCubemapWizard脚本。这个脚本可以在与本文同级的Scripts目录下找到。把该脚本放到工程目录里，可以看到菜单栏GameObject菜单里多了一个Render into Cubemap选项。
首先隐藏掉场景中的动态对象（水也要隐藏），只留下需要渲染到环境贴图中的对象。在Project面板中新建一个Cubemap，选中该文件，在Inspector窗口中勾选Readable选项。点击菜单栏Game Object -> Render into Cubemap，此时会弹出一个窗口。

![img01](http://www.cherryfrog.net/images/blogs/water/reflCubemap/reflCubemap02.png)

将Hierarchy面板中的水对象拖到Render From Position框中，将创建的Cubemap拖入Cubemap框中；点击Render！按钮，环境贴图就渲染好了。

## 着色器
首先定义Properties。
```
//水体主颜色
_Color ("Color Tint", Color) = (1, 1, 1, 1)
//反射颜色
_ReflectColor ("Reflection Color", Color) = (1, 1, 1, 1)
//反射率
_ReflectRatio ("Reflect Ratio", Range(0, 1)) = 1
//菲涅尔率
_FresnelRatio ("Fresnel Ratio", Range(0, 1)) = 0.5
//环境贴图
_Cubemap("Reflection Cubemap", Cube) = "_Skybox" {}
//水波幅度
_Amplify ("Wave Amplify", float) = 0.3
//频率
_Frequency ("Wave Frequency", float) = 1
//水波速度
_Speed ("Wave Speed", float) = 1
//波纹中心
_Center ("Wave Center", Vector) = (1,1,0,0)
```
定义输入输出结构体：
```
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
};
```
接着，编写顶点着色器。这个着色器的功能很简单，完成顶点变换和一些参数的计算即可。
```
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
```
然后是片元着色器。在其中实现反射计算。
```
fixed4 frag (v2f i) : SV_Target
{
  fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

  fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

  fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(i.worldNormal, worldLightDir));

  fixed3 fresnel = _FresnelRatio + (1 - _FresnelRatio) * pow(1 - dot(worldViewDir, worldNormal), 5);

  fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;

  fixed3 color = ambient + lerp(diffuse, reflection, _ReflectRatio) * fresnel;

  return fixed4(color, 1);
}
```
使用texCUBE函数对环境贴图进行采样，得到反射颜色；然后按照反射率将反射颜色加到漫反射颜色上，并加上菲涅尔系数的影响。完整的着色器代码，可以在Scripts/WaterWithReflectionCubemap.shader文件中找到。

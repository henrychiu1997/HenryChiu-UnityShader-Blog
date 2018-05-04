# 水面的法线贴图
应用在水面的法线贴图和普通的法线贴图并无二至。法线贴图的原理属于比较基础的知识，这里就不说了，我采用的是《UnityShader入门精要》里的法线贴图代码。

## 核心代码
我们需要在世界坐标系下计算法线。具体来讲，在顶点着色器内计算从切线坐标到世界坐标的变换矩阵(TtoW)，把矩阵传给片元着色器，片元着色器通过法线贴图和转换矩阵计算法线。
那么，首先在v2f结构体中定义变换矩阵：
```
struct v2f
{
  ……
  fixed4 TtoW0 : TEXCOORDx;
  fixed4 TtoW1 : TEXCOORDx+1;
  fixed4 TtoW2 : TEXCOORDx+2;
};
```
这里定义了三个四维向量，分别储存矩阵的三行。
接下来，在顶点着色器计算该矩阵：
```
fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
fixed3 worldBinormal = cross(o.worldNormal, worldTangent) * v.tangent.w;
o.TtoW0 = float4(worldTangent.x, worldBinormal.x, o.worldNormal.x, o.worldPos.x);
o.TtoW1 = float4(worldTangent.y, worldBinormal.y, o.worldNormal.y, o.worldPos.y);
o.TtoW2 = float4(worldTangent.z, worldBinormal.z, o.worldNormal.z, o.worldPos.z);
```
最后，片元着色器计算法线：
```
fixed3 worldNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
worldNormal.xy *= _NormalScale;
worldNormal.z = sqrt(1.0 - saturate(dot(worldNormal.xy, worldNormal.xy)));
worldNormal = normalize(fixed3(dot(i.TtoW0.xyz, worldNormal), dot(i.TtoW1.xyz, worldNormal), dot(i.TtoW2.xyz, worldNormal)));
```

可以在顶点着色器中对法线贴图的uv坐标进行偏移，以实现扰动随波飘动的效果：
```
o.uv = TRANSFORM_TEX(v.texcoord, _NormalTex);
```
完整的代码可以在Scripts/waterWithNomralTex.shader文件下找到。

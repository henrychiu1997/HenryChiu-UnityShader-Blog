<script type="text/javascript" async src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML">
</script>
# 边缘光（Rim light）
先来看一下实现效果：
![img01](http://www.cherryfrog.net/images/blogs/outline-rimlight-001.jpg)


## 原理
边缘光的实现原理非常简单。通过视角方向和物体表面某点的法线方向的夹角来判断表面某点是否处于边缘上。当夹角越接近90度，说明该点越接近边缘。如果该点越接近边缘，那么该点越亮。
以下图为例，右边是待观察球体的截面，点V是观察点（摄像机所在的点）。v1和v2是两条方向不同的视线向量，A和B分别是它们与球体表面的交点。n1和n2是对应的表面法线向量。可以看出，相比v2和n2的夹角，v1与n1的夹角更加接近90度，因此认为B点比A点更加接近边缘。
![img02](http://www.cherryfrog.net/images/blogs/outline-rimlight-002.jpg)

在代码中，我们使用CG内置的点乘运算（dot函数）来计算两个向量夹角的余弦值。有关dot函数的更多原理与本文无关，如果不了解该函数，请先记住下面的结论：dot函数的输入为两个向量，返回值越接近0，说明两个向量越接近垂直。在已知**归一化**的视角向量viewDir和表面法线向量normalDir后，它们之间的夹角的余弦值可以表示为：dot(viewDir, normalDir)。由于点乘值可能为负，但计算光照时不应该出现负数，因此要用max函数将点乘值约束到非负区间，即：
\[rim = 1 - max(0, dot(viewDir, normalDir))\]

上面这个式子的值在0到1之间。物体表面某点越接近边缘，该值越低。为了便于思考，我们对上面的式子稍作修改，变为：
rim = 1 - max(0, dot(viewDir, normalDir))
这样一来，物体表面某点越接近边缘，rim值越高。我们就可以使用rim值来计算边缘光了。

## 实践
Unity的官方文档中已经有了边缘光在表面着色器中的实现（[文档链接]:(https://docs.unity3d.com/Manual/SL-SurfaceShaderExamples.html)）。官方的代码还是非常简单易懂的，所以我只写它在顶点片元着色器中的实现。


# 使用额外Pass实现描边效果
来，先看效果：
![img01](http://www.cherryfrog.net/images/blogs/outline-ep-001.jpg)


# 原理
在shader中使用一个额外的Pass来渲染物体。这个Pass的作用是，在View视角空间下，通过修改物体顶点坐标的方式使物体“扩大一圈”，并渲染为纯色；然后在接下Pass使用普通着色方式进行着色。两个Pass的渲染结果相叠加，就能产生描边效果。过程如图所示：
![img02](http://www.cherryfrog.net/images/blogs/outline-ep-002.jpg)

其中的Pass1就是刚才说的额外Pass。

# 实践

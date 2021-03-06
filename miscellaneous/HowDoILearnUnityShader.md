# 我的UnityShader入门之路

我大学是学游戏开发的，顺带学了学网页前后端那些东西，用来搭自己的网站。算起来，图形学和shader这方面我已经自学了有两年多了。从当初对shader一无所知到会写一些渲染效果，其中还是有段很艰难的学习过程。在此总结一下学习shader中的一些感悟和方法。



**一、先从图形学基础开始学起。**

对于没有什么图形学实际编程经验的人来说，要掌握Unity3d的shader编程还是挺有难度的。首先要明白，shader只是渲染中的一小部分而已，shader必须配合渲染管线才能正常的工作。如果不理解渲染原理，就很难理解shader的写法。因此，不建议没有基础的人直接开始学shader编程，先把图形学的理论基础打牢。

计算机图形学中的内容繁多复杂，对于初学者先掌握以下几点：
1、线性代数。这是基础中的基础了，渲染中的很多操作本质上都是矩阵变换。学好线性代数对理解渲染原理很有好处。
2、渲染管线。着重学习顶点的模型空间->世界空间->观察空间->剪裁空间->屏幕空间变换原理。学习了渲染管线，就可以理解保存在硬盘上的数据是如何一步步被加工处理最终成为屏幕上的图像的。然后才能理解shader是如何工作的。

推荐图书《3D游戏与计算机图形学中的数学方法》。这本书中的内容很多，先学前5章就够了。


**二、用底层图形API写一个简单的三维渲染效果**

Unity3D游戏引擎对底层图形API做了封装，这让开发工作变得简单。但要学习着色器编程，不可以不了解底层的渲染管线原理。有两大底层图形API：DirectX和OpenGL，学哪个都是一样的。这里不是让你完全掌握这些底层API，你只需要能画出一个简单的物体就行了。通过这一步，你实际上利用代码再次理解了一遍渲染管线，后面学shader就更加简单了。

我个人更推荐学习OpenGL，原因很简单，github上有一份简洁易懂的OpenGL教程：LearnOpenGL。这个教程有中文翻译版（[链接](https://learnopengl-cn.github.io/)）。不得不说这是一份非常好的教程，深入浅出。另外，该教程会教你写一个最简单的着色器了。把第一章学完，这时你已经能在屏幕上画出一个简单的立方体了。


**三、正式开学Unity3d的shader**

有了以上的基础，现在可以正式开始学Unity着色器编程了。推荐《UnityShader入门精要》这本书。Unity着色器编程的内容非常多，不太好总结。总的老说，多看书多上网查资料，多写代码，慢慢得就会对着色器编程愈加熟练。

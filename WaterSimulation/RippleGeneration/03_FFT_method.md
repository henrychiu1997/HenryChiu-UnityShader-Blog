# 基于FFT方法的海面波浪生成
采用基于统计学的方法生成海面高度场，使用快速傅里叶变换计算海面高度，可以得到复杂且真实的海面波浪。学习个技术时，不得不提到2001年SIGGRAPH上的那篇经典文章《[Simulating Ocean Water](http://www-evasion.imag.fr/Membres/Fabrice.Neyret/NaturalScenes/fluids/water/waves/fluids-nuages/waves/Jonathan/articlesCG/simulating-ocean-water-01.pdf)》。这里简单翻译一下那篇文章。

## 统计学波浪模型（Statistical Wave Models）
首先，海面上某点的高度可以表示为关于水平坐标和时间的函数，即：

![img-f01](http://www.cherryfrog.net/images/blogs/water/ripple/fft-f01.png)

其中，向量x表示该点的水平坐标，t表示时间。
海面高度h的公式为：

![img-f02](http://www.cherryfrog.net/images/blogs/water/ripple/fft-f02.png)

其中，

![img-f02](http://www.cherryfrog.net/images/blogs/water/ripple/fft-f02.png)

n和m分别是位于区间\[-N/2, N/2]和\[-M/2, M/2]之间的整数。N和M是海浪高度纹理图的长宽，一般取值16到2048间，需为2的次方。
Lx和Lz是要模拟的海面的长度和宽度，这个取值可以根据实际情况来。

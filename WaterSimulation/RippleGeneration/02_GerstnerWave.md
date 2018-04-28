# Gerstner Wave
![img01](http://www.cherryfrog.net/images/blogs/water/ripple/gWave01.png)

Gerstner波在很早很早以前就有了，用于模拟海面。后来才被引入计算机图像学中。这种波的波峰比正弦波的波峰更加尖锐，更符合现实中的海洋波面，因此Gerstner波常用于海面模拟。

## 公式
注意，为了方便在Unity中的实现，以下的公式都是以xz平面为水平面，y轴为垂直方面来表示的。
对于给定的x和z，GerstnerWave生成的海面上的点可以表示为：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/gWave02.png)

其中，Q表示波峰的尖锐程度。Q的值应位于\[0,1/ωA]之间。Q值越小，波形越接近正弦波；Q越大，波峰越尖锐；Q大于1/ωA后，波峰将会变为环。A表示波幅，D是一个二维向量，表示波的方向。可以看出，Gerstner波的实际就是在普通正弦波的基础上，在水平方向上添加一个cos波的位移，以得到更尖锐的波峰。
对于多个Gerstner波的叠加，其公式表示为：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/gWave03.png)

法线为：

![img01](http://www.cherryfrog.net/images/blogs/water/ripple/gWave04.png)

## 参考资料
https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html

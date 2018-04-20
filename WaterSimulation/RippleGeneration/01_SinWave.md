# 使用正弦波生成水面波纹
![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave01.png)

## 空间正弦曲面
正弦波的公式是：
![img01](http://www.cherryfrog.net/images/blogs/water/ripple/sinWave02.png)

其中，A表示振幅，ω表示角速度（可以看作频率），φ表示初相。
现在把正弦波推广到空间曲面：

在Unity中，xz平面才是水平面，y轴是垂直方向。因此，把上面的曲面函数改写为如下形式：

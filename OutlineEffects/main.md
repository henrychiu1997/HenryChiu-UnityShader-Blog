# 使用UnityShader实现描边效果
给物体描边是游戏开发中比较常见的一种画面效果。比如在游戏《风暴英雄》中，玩家选取英雄时，英雄身上会出现一层淡蓝色的描边效果。在Unity中，有许多方法可以实现描边。
![img01](http://www.cherryfrog.net/images/blogs/outline-001.jpg)
[图片来源](https://www.bilibili.com/video/av7255515/)


这里提一下常见的几种实现方法：
* **边缘光（Rim Light）**
* **使用额外pass渲染**
* **图像后处理（Post-processing）**

其中边缘光是最简单最快的一种描边方法，但通常情况下也是效果最差的（具体还得看项目需求）。额外pass的方法略显复杂，但效果不错。基于图像后处理的方法相比而言更加复杂，但可以实现更好的效果。

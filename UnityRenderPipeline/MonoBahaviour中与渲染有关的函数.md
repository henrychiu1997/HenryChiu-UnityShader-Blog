# MonoBehaviour中与渲染有关的函数
Unity3d的脚本生命周期内的循环大概由以下几个部分组成：物理计算（FixedUpdate等）、输入、逻辑循环（Update等）、渲染。官网上有一张图详细介绍了脚本生命周期内的各种事件函数的执行顺序（[链接](https://docs.unity3d.com/Manual/ExecutionOrder.html)），这篇文章总结下有关场景渲染（Scene rendering）的事件函数。

MonoBehaviour中与场景渲染有关的事件函数共有8个：
* OnWillRenderObject
* OnPreCull
* OnBecameVisible
* OnBecameInvisible
* OnPreRender
* OnRenderObject
* OnPostRender
* OnRenderImage

根据这些函数的名字不难理解函数的功能。首先要明确的一点是，既然MonoBehaviour类是挂载到游戏物体上的，那么以上这些函数必然是其对应的物体进入渲染流程时才会被触发。这些函数在实现一些画面特效时很实用（或者说几乎是必备的）。

## OnWillRenderObject

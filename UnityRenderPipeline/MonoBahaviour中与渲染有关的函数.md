# MonoBehaviour中与渲染有关的函数
Unity3d的脚本生命周期内的循环大概由以下几个部分组成：物理计算（FixedUpdate等）、输入、逻辑循环（Update等）、渲染。官网上有一张图详细介绍了脚本生命周期内的各种事件函数的执行顺序（[链接](https://docs.unity3d.com/Manual/ExecutionOrder.html)），这篇文章总结下有关场景渲染（Scene rendering）的事件函数。

MonoBehaviour中与场景渲染有关的事件函数共有8个：

(1)
* OnWillRenderObject
* OnBecameVisible
* OnBecameInvisible
* OnRenderObject

(2)
* OnPreCull
* OnPreRender
* OnPostRender
* OnRenderImage

根据这些函数的名字不难理解函数的功能。首先要明确的一点是，(1)组中的函数是其对应的物体进入渲染流程时才会被触发，基本上只控制脚本对应的物体的渲染。(2)组中的函数只有在脚本被挂载到摄像机上时才会被触发，其控制的是摄像机的渲染。

## OnWillRenderObject()
渲染流程中执行的第一个事件函数，当该物体可见，引擎已完成对其的剔除操作，开始渲染该物体时被调用（可见的意思是当前正在工作的摄像机能看见该物体）。

## OnRenderObject()
在摄像机完成渲染场景后，可以使用该函数自行渲染新物体（当然此时绘制的物体在场景中是最靠前的，不会被遮挡）。如果需要单独渲染少量物体，使用此函数比使用Camere.Render方法的效率要高。

## OnBecameVisible()和OnBecameInvisible()
这两个函数很简单，当物体在摄像机中变为可见或不可见时被调用。这两个函数常用于物体可见性判断。

## OnPreCull()
在摄像机进行剔除处理前被调用。通常该函数用于改变摄像机的参数。然后摄像机会使用新参数来对场景中的物体进行剔除。

## OnPreRender()
在摄像机完成剔除操作后，开始渲染场景前被调用。

## OnPostRender()
在摄像机完成渲染场景后被调用。

## OnRenderImage(RenderTexture src, RenderTexture dest)
这个函数的执行比onPostRender更晚，它只有在所有渲染都完成后才会被调用。使用这个函数可以操控修改摄像机的渲染结果。渲染结果作为src（源渲染纹理）传入函数，函数中进行处理后将结果作为dest（目标渲染纹理）传出。该函数经常用于制作后期特效（例如运动模糊）等。我单独开一个目录写后期特效。


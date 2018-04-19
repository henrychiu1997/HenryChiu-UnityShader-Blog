using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Outline : MonoBehaviour {

    //用于preOutline过程的相机
    Camera preOutlineCamera = null;

    //用来存放preOutline结果的RT
    RenderTexture renderTexture = null;

    //用来完成preOutline过程的shader
    public Shader preOutlineShader = null;

    //用来完成描边过程的材质
    public Material outlineMat = null;

    //降采样系数
    public int downSample = 2;
    //高斯模糊迭代次数
    public int iteration = 2;
    
    void Awake () {
        //创建用于preOutline过程的摄像机
        GameObject go = new GameObject();
        preOutlineCamera = go.AddComponent<Camera>();
        //使用主相机的参数初始化preOutlineCemera，并将其背景颜色设为（0，0，0，0）
        preOutlineCamera.CopyFrom(Camera.main);

        preOutlineCamera.clearFlags = CameraClearFlags.SolidColor;
        preOutlineCamera.backgroundColor = new Color(0, 0, 0, 0);
        preOutlineCamera.SetReplacementShader(preOutlineShader, "");
        preOutlineCamera.enabled = false;

        //初始化renderTexture
        renderTexture = RenderTexture.GetTemporary(preOutlineCamera.pixelWidth / downSample, preOutlineCamera.pixelHeight / downSample, 0);
        preOutlineCamera.targetTexture = renderTexture;
    }
    
    //在物体被销毁时，释放renderTexture并删除摄像机
    private void OnDestroy()
    {
        if (renderTexture)
            RenderTexture.ReleaseTemporary(renderTexture);
        Destroy(preOutlineCamera.gameObject);
    }


    //在渲染前，使用preOutlineShader渲染物体
    private void OnPreRender()
    {
        preOutlineCamera.Render();
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (outlineMat && renderTexture)
        {
            RenderTexture temp1 = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample, 0);
            RenderTexture temp2 = RenderTexture.GetTemporary(source.width / downSample, source.height / downSample, 0);

            #region 对renderTexture进行模糊处理
            outlineMat.SetTexture("_MainTex", renderTexture);
            Graphics.Blit(renderTexture, temp1, outlineMat, 0);
            Graphics.Blit(temp1, temp2, outlineMat, 1);
            for (int i = 0; i < iteration -1; i++)
            {
                Graphics.Blit(temp2, temp1, outlineMat, 0);
                Graphics.Blit(temp1, temp2, outlineMat, 1);
            }
            #endregion

            //使用PostOutline的Pass2输出轮廓图
            outlineMat.SetTexture("_BlurTex", temp2);
            outlineMat.SetTexture("_MainTex", renderTexture);
            Graphics.Blit(renderTexture, temp1, outlineMat, 2);

            //使用Pass3输出最终结果
            outlineMat.SetTexture("_BlurTex", temp1);
            outlineMat.SetTexture("_MainTex", source);
            Graphics.Blit(source, destination, outlineMat, 3);

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);       
        }
    }
}

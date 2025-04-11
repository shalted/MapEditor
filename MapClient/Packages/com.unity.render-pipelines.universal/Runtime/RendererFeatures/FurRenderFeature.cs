using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//[ExecuteInEditMode]
public class FurRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FilterSettings
    {
        // TODO: expose opaque, transparent, all ranges as drop down
        public RenderQueueType RenderQueueType;
        public LayerMask LayerMask = 1;
        public string[] PassNames;

        public FilterSettings()
        {
            RenderQueueType = RenderQueueType.Opaque;
            LayerMask =  ~0;
            PassNames = new string[] { "FurRendererLayer"};
        }
    }

    public static FurRenderFeature instance;
    
    /// <summary>
    /// This function is called when the object becomes enable and active.
    /// </summary>
    ///
    [System.Serializable]
    public class PassSettings
    {
        public string passTag = "FurRenderer";
        public string ProceduralPassTag = "FurObject";
        [Header("Settings")]
        public bool ShouldRender = true;
        [Tooltip("Set Layer Num")]
        [Range(1, 200)]public int PassLayerNum = 20;
        [Range(1000, 5000)] public int QueueMin = 2000;
        [Range(1000, 5000)] public int QueueMax = 5000;
        public RenderPassEvent PassEvent = RenderPassEvent.AfterRenderingSkybox;

        public FilterSettings filterSettings = new FilterSettings();
    }

    public class FurRenderPass : ScriptableRenderPass
    {
        string m_ProfilerTag;
        RenderQueueType renderQueueType;
        private PassSettings settings;
        private FurRenderFeature furRenderFeature = null;
        public List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
        //private ShaderTagId shadowCasterSTI = new ShaderTagId("ShadowCaster");
        private FilteringSettings filter;
        //public Material overrideMaterial { get; set; }
        //public int overrideMaterialPassIndex { get; set; }
        
        public SkinnedMeshRenderer SMRenderer;
        private Material m_FurMat;
        private Matrix4x4 m_Matrix;
        private GraphicsBuffer m_IndexBuffer;
        private GraphicsBuffer m_DeformedDataBuffer;
        private GraphicsBuffer m_StaticDataBuffer;
        private GraphicsBuffer m_SkinningDataBuffer;
        private int m_IndexCount;
        private int m_InstanceCount;
        private bool hasSkinnedMeshRenderer = false;
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // var furObject = GameObject.FindGameObjectWithTag(settings.ProceduralPassTag);
            // if (furObject == null)
            // {
            //     //Debug.LogWarning("Not found Fur !!!!!!!!!!");
            //     return;
            // }
            //
            // SkinnedMeshRenderer skinnedMeshRenderer = furObject.GetComponentInChildren<SkinnedMeshRenderer>();
            // if (skinnedMeshRenderer == null)
            // {
            //     //Debug.LogWarning("Tags Model does not have a SkinnedMeshRenderer component.");
            //     hasSkinnedMeshRenderer = false;
            //     return;
            // }
            // else
            // {
            //     //Debug.LogWarning("Tags Model does not have a SkinnedMeshRenderer component.");
            //     hasSkinnedMeshRenderer = true;
            // }
            // SMRenderer = skinnedMeshRenderer;
            //
            // m_DeformedDataBuffer = SMRenderer.GetVertexBuffer();
            // SMRenderer.sharedMesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
            // int _uvStreamID = SMRenderer.sharedMesh.GetVertexAttributeStream(VertexAttribute.TexCoord0);
            // m_StaticDataBuffer = SMRenderer.sharedMesh.GetVertexBuffer(_uvStreamID);
            // //m_SkinningDataBuffer = Renderer.sharedMesh.GetVertexBuffer(Renderer.sharedMesh.GetVertexAttributeStream(VertexAttribute.BlendWeight));
            //
            // m_IndexBuffer = SMRenderer.sharedMesh.GetIndexBuffer();
            // m_IndexCount = m_IndexBuffer.count;
            //
            //
            // m_FurMat = SMRenderer.sharedMaterial;
            // m_FurMat.SetBuffer("_DeformedData", m_DeformedDataBuffer);
            // m_FurMat.SetBuffer("_StaticData", m_StaticDataBuffer);
            //
            //
            // m_Matrix = SMRenderer.transform.parent.Find("root").localToWorldMatrix;
            // //m_InstanceCount = Mathf.FloorToInt(m_FurMat.GetFloat("_FUR_OFFSET"));
        }

        public FurRenderPass(PassSettings setting, FurRenderFeature render,FilterSettings filterSettings)
        {
            m_ProfilerTag = setting.passTag;
            string[] shaderTags = filterSettings.PassNames;
            this.settings = setting;
            this.renderQueueType = filterSettings.RenderQueueType;
            furRenderFeature = render;
            //过滤设定
            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = setting.QueueMin;
            queue.upperBound = setting.QueueMax;
            filter = new FilteringSettings(queue,filterSettings.LayerMask);
            if (shaderTags != null && shaderTags.Length > 0)
            {
                foreach (var passName in shaderTags)
                    m_ShaderTagIdList.Add(new ShaderTagId(passName));
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            SortingCriteria sortingCriteria = (renderQueueType == RenderQueueType.Transparent)
                ? SortingCriteria.CommonTransparent
                : renderingData.cameraData.defaultOpaqueSortFlags;
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            using (new ProfilingScope(cmd, new ProfilingSampler("fur renderererer")))
            {

                //=============================================================
                //draw objects(e.g. reflective wet ground plane) with lightmode "MobileSSPRWater", which will sample _MobileSSPR_ColorRT
                DrawingSettings baseDrawingSetting, layerDrawingSetting;
                //BaseLayer DrawingSetting
                //if (m_ShaderTagIdList.Count > 0)
                //    baseDrawingSetting = CreateDrawingSettings(m_ShaderTagIdList[0], ref renderingData,
                //        renderingData.cameraData.defaultOpaqueSortFlags);
                //else return;
                if (m_ShaderTagIdList.Count > 0)
                {
                    layerDrawingSetting = CreateDrawingSettings(m_ShaderTagIdList[0], ref renderingData,
                        renderingData.cameraData.defaultOpaqueSortFlags);
                }
                else return;

                float inter = 1.0f / settings.PassLayerNum;
                //BaseLayer
                cmd.Clear();
                cmd.SetGlobalFloat("_FUR_OFFSET", 0);
                context.ExecuteCommandBuffer(cmd);
                //context.DrawRenderers(renderingData.cullResults,ref baseDrawingSetting,ref filter);
                //TransparentLayer
                for (int i = 1; i < settings.PassLayerNum; i++)
                {
                    cmd.Clear();
                    cmd.SetGlobalFloat("_FUR_OFFSET", i * inter);
                    context.ExecuteCommandBuffer(cmd);
                    context.DrawRenderers(renderingData.cullResults, ref layerDrawingSetting, ref filter);
                }

                if (!hasSkinnedMeshRenderer)
                {
                    // 没有 SkinnedMeshRenderer 组件，直接返回
                    return;
                }
                else
                {
                    cmd.Clear();
                    cmd.SetGlobalFloat("_FUR_NUM", settings.PassLayerNum);
                    cmd.DrawProcedural(m_IndexBuffer, m_Matrix, m_FurMat, 7, MeshTopology.Triangles, m_IndexCount,
                        settings.PassLayerNum);
                    context.ExecuteCommandBuffer(cmd);
                }
            }

            CommandBufferPool.Release(cmd);
        }

        /// Cleanup any allocated resources that were created during the execution of this render pass.
        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }
    public PassSettings settings = new PassSettings();
    FurRenderPass m_ScriptablePass;

    public override void Create()
    {
        instance = this;
        FilterSettings filter = settings.filterSettings;
        m_ScriptablePass = new FurRenderPass(settings, this, filter);
        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = settings.PassEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}



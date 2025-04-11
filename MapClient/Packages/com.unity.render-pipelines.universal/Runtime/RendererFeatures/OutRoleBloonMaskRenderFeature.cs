using System;
using System.Collections;
using System.Collections.Generic;

namespace UnityEngine.Rendering.Universal
{
    public class OutRoleBloonMaskRenderFeature : ScriptableRendererFeature
    {
        [Serializable]
        public class OutRoleBloonMaskSetting
        {
            public LayerMask layerMask = 0;
            public RenderPassEvent passEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }
        public OutRoleBloonMaskSetting settings = new OutRoleBloonMaskSetting();
        private OutRoleBloomMaskPass m_ScriptablePass;
        
        private PostProcessData m_data;
        
        private RenderTargetIdentifier sourceRTDepth;

        public override void Create()
        {
            if (isActive)
            {
                m_ScriptablePass = new OutRoleBloomMaskPass(settings);
            }
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            var m_bloom = stack.GetComponent<MixBloom>();
            if (m_bloom != null && m_bloom.IsActive() && m_bloom.UseAlpha.value )
            {
                //只在主相机画，我们也要确保它最多只画一次
                if (m_ScriptablePass != null && renderingData.cameraData.postProcessEnabled)
                {
                    renderer.EnqueuePass(m_ScriptablePass);
                }   
            }
        }
        
        public class OutRoleBloomMaskPass : ScriptableRenderPass
        {
            //标签
            private const string m_ProfilerTag = "Draw Role Bloom Mask";
            internal static readonly string RoleBloomMaskName = "_RoleBloomMaskTexture";
            internal static readonly int RoleBloomMaskPropertyID = Shader.PropertyToID("_RoleBloomMaskTexture");
            ProfilingSampler m_ProfilingSampler = new ProfilingSampler(m_ProfilerTag);
            internal List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
            RenderTargetHandle m_RoleBloomMaskTexture;

            private OutRoleBloonMaskSetting setting;
            private RenderTargetIdentifier sourceRTDepth;

            public OutRoleBloomMaskPass(OutRoleBloonMaskSetting setting)
            {
                this.setting = setting;
                renderPassEvent = setting.passEvent;
                m_RoleBloomMaskTexture.Init(RoleBloomMaskName);
                m_ShaderTagIdList.Add(new ShaderTagId("RoleBloomMask"));
            }
            
            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                var rtdesc = cameraTextureDescriptor;
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8))
                {
                    rtdesc.colorFormat = RenderTextureFormat.R8;
                }
                else
                {
                    rtdesc.colorFormat = RenderTextureFormat.ARGB32;
                }
                
                rtdesc.useMipMap = false;
                rtdesc.msaaSamples = 1;
                rtdesc.depthBufferBits = 24;
                rtdesc.sRGB = false;
                

                rtdesc.width = 500;
                rtdesc.height = Mathf.FloorToInt(500 * (1.0f * cameraTextureDescriptor.height)/cameraTextureDescriptor.width);
                

                cmd.GetTemporaryRT(m_RoleBloomMaskTexture.id, rtdesc);
                
                ConfigureTarget(m_RoleBloomMaskTexture.id);

                ConfigureClear(ClearFlag.All, new Color(0, 0, 0, 1)); 
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                // 执行拷贝命令 
                DrawingSettings drawingSettings =
                    CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, SortingCriteria.CommonTransparent);
                FilteringSettings
                    filteringSetting =
                        new FilteringSettings(RenderQueueRange.all, (int) setting.layerMask);
                
                var cmd = CommandBufferPool.Get(m_ProfilerTag);
                //context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSetting);
                cmd.SetGlobalTexture(RoleBloomMaskPropertyID, m_RoleBloomMaskTexture.id);
                
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            
            }
            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                this.sourceRTDepth = renderingData.cameraData.renderer.cameraDepthTarget;

            }

            public override void FrameCleanup(CommandBuffer cmd)
            {
                base.FrameCleanup(cmd);
                cmd.ReleaseTemporaryRT(m_RoleBloomMaskTexture.id);
            }
        }
    }


}
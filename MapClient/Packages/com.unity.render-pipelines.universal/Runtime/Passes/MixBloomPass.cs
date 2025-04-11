using System;

namespace UnityEngine.Rendering.Universal
{
    public class MixBloomPass : ScriptableRenderPass
    {
        const string CommandBufferTag = "MixBloom Pass";
        // MixBloomRenderFeature.MixBloomSetting settings;

        private Material m_Material;
        MixBloom m_MixBloom;
        
        private static readonly int TEXCOUNT=4;

        RenderTargetIdentifier m_Source;
        
        private RenderTargetHandle[] BloomBuffterTex=new RenderTargetHandle[TEXCOUNT];    
        private RenderTargetHandle[] BloomTempBuffter=new RenderTargetHandle[TEXCOUNT];

        private RenderTargetHandle MixBloomTex;
        
        private static readonly int Threshold = Shader.PropertyToID("_BloomThreshold");
        private static readonly int Intensity = Shader.PropertyToID("_BloomIntensity");
        private static readonly int MixRatio = Shader.PropertyToID("_BloomMixRatio");
        private static readonly int ClampMax = Shader.PropertyToID("_BloomClampMax");
        private static readonly int TexelRadius = Shader.PropertyToID("_TexelRadius");
        private static readonly int _BackGroudBloomIntensity = Shader.PropertyToID("_BackGroudBloomIntensity");

        internal static readonly string MixBloomTexName = "_MixBloomTexture";
        
        internal static readonly int MixBloomTexID = Shader.PropertyToID("_MixBloomTexture");
        
        internal static readonly int BloomBuffterTex0ID = Shader.PropertyToID("_BloomBuffterTex0");
        internal static readonly int BloomBuffterTex1ID = Shader.PropertyToID("_BloomBuffterTex1");
        internal static readonly int BloomBuffterTex2ID = Shader.PropertyToID("_BloomBuffterTex2");

        private static readonly string RatioKeyword = "_CUSTOMRATIO_ON";         
        internal static readonly string MixBloomKeyword = "_MIXBLOOM_ON";
        
        internal static readonly string AlphaMaskKeyword = "_ALPHAMASK_ON";

        
        
        public MixBloomPass(MixBloomRenderFeature.MixBloomSetting setting)
        {
            //this.settings = setting;

            for (int i = 0; i < TEXCOUNT; i++)
            {
                BloomBuffterTex[i].Init("BloomBuffterTex"+i);
                BloomTempBuffter[i].Init("BloomTempBuffter"+i);
            }
            
            MixBloomTex.Init(MixBloomTexName);
        }
        
        // 设置渲染参数
        public void Setup(MixBloom mixBloom, Material material)
        {
            m_MixBloom = mixBloom;
            //this.m_Source = source;
            m_Material = material;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            RenderTextureDescriptor descriptor = cameraTextureDescriptor;
            descriptor.width = descriptor.width>>2;
            descriptor.height = descriptor.height>>2;
            descriptor.depthBufferBits = 0;

            cmd.GetTemporaryRT(MixBloomTex.id, descriptor,FilterMode.Bilinear);
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            var m_bloom = stack.GetComponent<Bloom>();
            m_bloom.intensity.value=0;
            
            var cmd = CommandBufferPool.Get(CommandBufferTag);

            Render(cmd, ref renderingData);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            Shader.EnableKeyword(MixBloomPass.MixBloomKeyword);
            if (m_MixBloom.CustomRatio.value)
            {
                m_Material.EnableKeyword(RatioKeyword);
                m_Material.SetVector(MixRatio, m_MixBloom.MixRatio.value);
            }
            else
            {
                m_Material.DisableKeyword(RatioKeyword);
            }

            if (m_MixBloom.UseAlpha.value)
            {
                m_Material.EnableKeyword(AlphaMaskKeyword);
                m_Material.SetFloat(_BackGroudBloomIntensity,m_MixBloom.BackGroudBloomIntensity.value);
            }
            else
            {
                m_Material.DisableKeyword(AlphaMaskKeyword);
            }
            
            m_Material.SetFloat(Threshold,m_MixBloom.Threshold.value);
            m_Material.SetFloat(ClampMax,m_MixBloom.ClampMax.value);
            m_Material.SetFloat(TexelRadius,m_MixBloom.TexelRadius.value);
            Shader.SetGlobalFloat(Intensity,m_MixBloom.Intensity.value);

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor; 
            // opaqueDesc.width = opaqueDesc.width>>2;
            // opaqueDesc.height = opaqueDesc.height>>2;
            opaqueDesc.width = opaqueDesc.width>>1;
            opaqueDesc.height = opaqueDesc.height>>1;
            opaqueDesc.depthBufferBits = 0;
            opaqueDesc.msaaSamples = 1;

            cmd.GetTemporaryRT( BloomBuffterTex[0].id, opaqueDesc, FilterMode.Bilinear);
            cmd.GetTemporaryRT( BloomTempBuffter[0].id, opaqueDesc, FilterMode.Bilinear);

            for (int i = 1; i < TEXCOUNT; i++)
            {
                cmd.GetTemporaryRT( BloomTempBuffter[i].id, (int)(opaqueDesc.width >>i),(opaqueDesc.height >>i),0,FilterMode.Bilinear,RenderTextureFormat.RGB111110Float);
                cmd.GetTemporaryRT( BloomBuffterTex[i].id, (int)(opaqueDesc.width >>i),(opaqueDesc.height >>i),0,FilterMode.Bilinear,RenderTextureFormat.RGB111110Float);
            }

            var cameraColorTarget = renderingData.cameraData.renderer.cameraColorTargetHandle;
            cmd.Blit(cameraColorTarget, BloomBuffterTex[0].Identifier(), m_Material, 0);   //降分辨率，同时提取高亮
 
            cmd.Blit(BloomBuffterTex[0].Identifier(), BloomTempBuffter[0].Identifier(), m_Material, 5);   //横向模糊
            cmd.Blit(BloomTempBuffter[0].Identifier(), BloomBuffterTex[0].Identifier(), m_Material, 6);   //纵向模糊

            for (int j = 0; j < TEXCOUNT-1; j++)
            {           
                cmd.Blit(BloomBuffterTex[j].Identifier(), BloomBuffterTex[j+1].Identifier());    //降分辨率
                cmd.Blit(BloomBuffterTex[j+1].Identifier(), BloomTempBuffter[j+1].Identifier(), m_Material, 5);    //横向模糊
                cmd.Blit(BloomTempBuffter[j+1].Identifier(), BloomBuffterTex[j+1].Identifier(), m_Material, 6);    //纵向模糊
                
            }

            cmd.SetGlobalTexture(BloomBuffterTex0ID, BloomBuffterTex[0].id);
            cmd.SetGlobalTexture(BloomBuffterTex1ID, BloomBuffterTex[1].id);
            cmd.SetGlobalTexture(BloomBuffterTex2ID, BloomBuffterTex[2].id);    
                         
            cmd.Blit(BloomBuffterTex[3].Identifier(),MixBloomTex.Identifier(),m_Material,3);     //合并混合

            cmd.SetGlobalTexture(MixBloomTexID, MixBloomTex.id);
        }
        
        public override void FrameCleanup(CommandBuffer cmd)
        {
            base.FrameCleanup(cmd);

            for (int i = 0; i < TEXCOUNT; i++)
            {
                cmd.ReleaseTemporaryRT(BloomTempBuffter[i].id);
                cmd.ReleaseTemporaryRT(BloomBuffterTex[i].id);
            }
        }
        
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            if (cmd == null)
                throw new ArgumentNullException("cmd");

            if (MixBloomTex != RenderTargetHandle.CameraTarget)
            {           
                cmd.ReleaseTemporaryRT(MixBloomTex.id);
            }
        }
    }
}

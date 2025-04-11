using System;

namespace UnityEngine.Rendering.Universal
{
    public class MixBloomRenderFeature : ScriptableRendererFeature
    {
        [Serializable]
        public class MixBloomSetting
        {
            public LayerMask layerMask = 1;

            // public Vector4 mixRatio = new Vector4(0.3f, 0.3f, 0.26f, 0.15f);
            public RenderPassEvent passEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            
            public Material material = null;
        }

        public MixBloomSetting settings = new MixBloomSetting();
        private MixBloomPass postPass;
        private MixBloom m_mixbloom;

        private static readonly string ShaderName = "ShiYue/URP/PostProcessing/MixBloom";
        private PostProcessData m_data;
        //private Shader m_mixbloomShader;

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            //if(renderingData.cameraData.gameType == CameraGameType.UI)
                //return;
            
            //if (renderingData.cameraData.gameType == CameraGameType.MainGame)
            //{
                Shader.DisableKeyword(MixBloomPass.MixBloomKeyword);
            //}

            bool isrenderlayer = IsRenderLayer(renderingData.cameraData.camera.gameObject.layer, settings.layerMask);
            //if (renderingData.cameraData.renderType == CameraRenderType.Base && isrenderlayer&& settings.material)
            if (isrenderlayer&& settings.material)
            {
                if (m_mixbloom == null)
                {
                    var stack = VolumeManager.instance.stack;
                    m_mixbloom = stack.GetComponent<MixBloom>();
                }
                //source = renderingData.cameraData.renderer.cameraColorTarget;//高版本调用，低版本cameraData.renderer报错
                //var cameraColorTarget = renderingData.cameraData.renderer.cameraColorTargetHandle;
                //if (renderingData.cameraData.gameType == CameraGameType.UI)
                //{
                    //UnityEngine.Rendering.Universal.UniversalRenderer forwardRenderer = (UnityEngine.Rendering.Universal.UniversalRenderer)renderer;
                    //cameraColorTarget = forwardRenderer.uiCameraColorTarget;
                //}
                if (m_mixbloom&&m_mixbloom.active)
                {
                    if (m_mixbloom.IsActive() && renderingData.cameraData.postProcessEnabled)
                    {
                        postPass.Setup(m_mixbloom, settings.material);
                        renderer.EnqueuePass(postPass);
                    }
                }
            }
        }

        public static bool IsRenderLayer(int layer, LayerMask rendermMask)
        {
            return (1 << layer & rendermMask.value) > 0;
        }


        public override void Create()
        {
            postPass = new MixBloomPass(settings);
            postPass.renderPassEvent = settings.passEvent;
            var stack = VolumeManager.instance.stack;
            m_mixbloom = stack.GetComponent<MixBloom>();
        }
    }
}
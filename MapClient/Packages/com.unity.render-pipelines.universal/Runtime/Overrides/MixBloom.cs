using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Bloom/MixBloom")]
    public class MixBloom : VolumeComponent, IPostProcessComponent
    {
        public MinFloatParameter Threshold = new MinFloatParameter(1f,0f);
        public MinFloatParameter Intensity = new MinFloatParameter(0f,0f);
        
        [Tooltip("启用自定义比例")]
        public BoolParameter CustomRatio = new BoolParameter(false);
        [Tooltip("混合比例(和值为1)")]
        public Vector4Parameter MixRatio= new Vector4Parameter(new Vector4(0.2f,0.55f,0.15f,0.3f));

        public FloatParameter ClampMax = new FloatParameter(20f);
        
        public FloatParameter TexelRadius = new ClampedFloatParameter(1f, 1, 4f);
        [Tooltip("开启透明通道遮罩")]
        public BoolParameter UseAlpha = new BoolParameter(false);
        [Tooltip("单独控制背景Bloom强度")]
        public MinFloatParameter BackGroudBloomIntensity = new MinFloatParameter(0f,0f);
        // 实现接口
        public bool IsActive() => Intensity.value > 0f;

        public bool IsTileCompatible()
        {
            return false;
        }
    }

}
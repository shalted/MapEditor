using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

namespace Script.Map
{
    public static class MapEnum
    {
        // 一些值是零时的，后续正式数值需修改，例如地图需要动态大小，屏幕需要实机大小
        public static int MapWidth = 7240;                // 地图宽度
        public static int MapHeight = 4600;               // 地图高度
        public static int MapNodeWidth = 1024;            // 切片宽度
        public static int MapNodeHeight = 1024;           // 切片高度    
        public const int ScreenWidth = 720;              // 屏幕宽度
        public const int ScreenHeight = 1660;            // 屏幕高度
        public const int Ppu = 100;                      // 坐标转换比例
        public static int CellSize = 128;                   //地图格子大小
        public static int BrushSize = 0;                    // 地图笔刷大小
        public static int ModelSize = 1;                   // 模型大小
        public static int ResourcesId = 3001;    // 资源ID
        
        public static string MapName = "Normal";        //默认地图名称
        public static string ChunkMode = "ResourceLayer";    // 地块层级
        public static string ChunkMaterialName = "m_ResourceLayer";    // 地块颜色
        
        public static bool IsLoadAllMap = true;                      // 坐标转换比例
        public static bool IsDeleteMode;       // 是否删除模式
        public static bool IsDragDrawMode;       // 是否拖拽绘制模式
        public static bool IsShowMeshMode;       // 是否拖拽绘制模式
        public static bool IsEditorMode = true;       // 是否编辑模式
        public static bool IsDrawChunk = true;       // 是否编辑模式
        
        public enum ChunkNameEnum
        {
            ResourceLayer,      // 资源层
            WalkableLayer,      // 行走层
            NonBuildableLayer,  // 不可建造层
            MonsterLayer,        // 怪物层
            TreePoint,        // 树
            BuildPoint,        // 建筑
            ResourcePoint,        // 资源
        }
        
        private static readonly Dictionary<string, int> ModelToChunkDictionary = new ()
        {
            ["玩家城池"] = (int)ChunkNameEnum.BuildPoint,
            ["野怪"] = (int)ChunkNameEnum.ResourcePoint,
            ["木头"] = (int)ChunkNameEnum.TreePoint,
            ["石头"] = (int)ChunkNameEnum.BuildPoint,
            ["铁矿"] = (int)ChunkNameEnum.ResourcePoint,
            ["粮食"] = (int)ChunkNameEnum.ResourcePoint,
            ["小城池"] = (int)ChunkNameEnum.BuildPoint,
            ["大城池"] = (int)ChunkNameEnum.BuildPoint,
        };
        
        
        private static readonly string[] ChunkNameList = { "ResourceLayer", "BornLayer", "NonBuildableLayer", "MonsterLayer", "TreePoint", "BuildPoint", "ResourcePoint"};
        
        private const int ChunkNameEnumCount = 4;
        public static void ChangeCurrentLayer(int chunkNameEnum)
        {
            IsDrawChunk = chunkNameEnum < ChunkNameEnumCount;
            ChunkMode = ChunkNameList[chunkNameEnum];
            ChunkMaterialName = $"m_{ChunkNameList[chunkNameEnum]}";
        }
        
        public static void ChangeCurrentLayerByName(string name)
        {
            ChunkMode = name;
            ChunkMaterialName = $"m_{name}";
        }
        
        public static void SetChunkMode(string chunkMode)
        
        {
            ChunkMode = chunkMode;
        }
        
        public static void ChangeLoadAllMap(bool isLoadAllMap)
        
        {
            IsLoadAllMap = isLoadAllMap;
        }
        
        public static void ChangeDeleteMode(bool isDeleteMode)
        {
            IsDeleteMode = isDeleteMode;
        }
        
        public static void ChangeDragDrawMode(bool isDragDrawMode) 
        {
            IsDragDrawMode = isDragDrawMode;
        }
        
        public static void ChangeShowMeshMode(bool isShowMeshMode)
        {
            IsShowMeshMode = isShowMeshMode;
        }

        public static void ChangeBrushSize(int size)
        {
            BrushSize = size;
        }
        
        public static void ChangeModelSize(int size)
        {
            ModelSize = size;
        }
        
        public static void ChangeResourcesName(int id)
        {
            ResourcesId = id;
            var config = WorldMap.GetModelConfigById(id);
            ChunkMode = ChunkNameList[ModelToChunkDictionary[config.Name]];
        }
        
        public static void ChangeResourcesByName(string name)
        {
            ChangeCurrentLayer(ModelToChunkDictionary[name]);
        }
        
        public static string GetChunkLayerById(int index)
        {
            return ChunkNameList[index];
        }
        
        private static Color HexToColor(string hex)
        {
            // 移除开头的 #
            hex = hex.Replace("#", "");

            // 如果长度不是 6 或 8，抛出异常
            if (hex.Length != 6 && hex.Length != 8)
                throw new System.ArgumentException("Invalid hex color code");

            // 解析颜色分量
            var r = byte.Parse(hex.Substring(0, 2), System.Globalization.NumberStyles.HexNumber);
            var g = byte.Parse(hex.Substring(2, 2), System.Globalization.NumberStyles.HexNumber);
            var b = byte.Parse(hex.Substring(4, 2), System.Globalization.NumberStyles.HexNumber);
            var a = hex.Length == 8 ? byte.Parse(hex.Substring(6, 2), System.Globalization.NumberStyles.HexNumber) : (byte)255;

            return new Color(r / 255f, g / 255f, b / 255f, a / 0.1f);
        }
    }
}
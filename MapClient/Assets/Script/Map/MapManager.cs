using System.Collections.Generic;
using Script.Chunk;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.UIElements;

namespace Script.Map
{
    public static class MapManager
    {
        private static readonly Dictionary<string, GameObject> ObjectMap = new Dictionary<string, GameObject>();
        private static Label _label;
        private static Label _label2;
        private static WorldMap _worldMap;
        
        public static void Init(WorldMap worldMap)
        {
            _worldMap = worldMap;
        }
        
        public static void RefreshMap()
        {
            var worldMap = GameObject.Find("WorldMap").GetComponent<WorldMap>();
            worldMap.RefreshMap();
        }

        public static void SetInspectorLabel(Label label, Label label2)
        {
            _label = label;
            _label2 = label2;
        }
        
        public static void SetInspectorLabelText1(string str = "")
        {
            _label.text = str;
        }
        
        public static void SetInspectorLabelText2(string str = "")
        {
            _label2.text = str;
        }
        
        public static void SetCurChunkLayer(GameObject gameObject, string name = "")
        {
            if (string.IsNullOrEmpty(name))
            {
                name = MapEnum.ChunkMode;
            }
            ObjectMap.Add(name, gameObject);
        }
        
        public static void SetCurChunkShowState(bool isShow, string name = "", string hideName = "")
        {
            MapEnum.isDrawArea = false;
            if (string.IsNullOrEmpty(name))
            {
                if (ObjectMap.TryGetValue(hideName, out var value1))
                {
                    value1.SetActive(false);
                }
                name = MapEnum.ChunkMode;
            }
            if (ObjectMap.TryGetValue(name, out var value))
            {
                value.SetActive(isShow);
            }
        }
        
        public static bool GetCurChunkShowState(string name = "")
        {
            if (string.IsNullOrEmpty(name))
            {
                name = MapEnum.ChunkMode;
            }
            return !ObjectMap.TryGetValue(name, out var value) || value.activeSelf;
        }

        public static void ClearMap()
        {
            _worldMap.CleanMap();
        }
        
        public static void ClearChunk()
        {
            _worldMap.CleanChunk();
        }
        
        public static void ClearModel()
        {
            _worldMap.CleanModel();
        }
        
        public static void SaveMap()
        {
            _worldMap.SaveDataToFile();
            _worldMap.SaveDataToFile2();
        }
        
        public static void SaveChunkMap()
        {
            _worldMap.SaveChunkMapData();
        }
        
        public static void SaveModelMap()
        {
            _worldMap.SaveModelMapData();
        }
        
        public static void SetAreaEditor()
        {
            MapEnum.isDrawArea = true;
        }
        
        public static void SetCurArea(string str)
        {
            MapEnum.AreaName = str;
        }
        
        public static void ClearArea(string str)
        {
            MapEnum.AreaName = str;
            _worldMap.CleanModel();
        }
        
    }
}
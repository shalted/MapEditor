using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Text;
using Script.Map;
using UnityEngine;

namespace Script.Model
{
    [SuppressMessage("ReSharper", "PossibleLossOfFraction")]
    public class ModelTree : MonoBehaviour
    {
        // Start is called before the first frame update
        private Transform _modelContainer;
        private Transform _modelNode;
        private StringBuilder _str;
        private StringBuilder _str2;
        Dictionary<string, Transform> _modelContentDict;
        Dictionary<string, Dictionary<string, List<ModelNode>>> _modelNodeDict;
        private WorldMap _worldMap;
        
        public void Init(WorldMap worldMap)
        {
            _worldMap = worldMap;
            _str = new StringBuilder(200);
            _str2 = new StringBuilder(2000);
            _modelContentDict = new Dictionary<string, Transform>();
            _modelNodeDict = new Dictionary<string, Dictionary<string, List<ModelNode>>>();
            _modelContainer = transform.Find("ModelContainer");
            _modelNode = transform.Find("ModelNode");
            LoadMapData();
        }
        
        public void AddNode(Vector3 worldPos)
        {
            var column = (int)Mathf.Floor((MapEnum.MapWidth / (2 * MapEnum.Ppu) + worldPos.x) / (MapEnum.CellSize / (float)MapEnum.Ppu));
            var row = (int)Mathf.Floor((MapEnum.MapHeight / (2 * MapEnum.Ppu) + worldPos.y) / (MapEnum.CellSize / (float)MapEnum.Ppu));
            UpdateMapNodeInfo(row, column);
            if (!MapEnum.IsEditorMode || !MapManager.GetCurChunkShowState("ModelTree")) return;
            ChangeModel(row, column, worldPos);
        }
        
        private void ChangeModel(int row, int column, Vector3 worldPos)
        {
            const int brushSize = 0;
            for (var i = row - brushSize; i <= row + brushSize; i++)
            {
                for (var j = column - brushSize; j <= column + brushSize; j++)
                {
                    _str.Clear();
                    _str.Append(i).Append("_").Append(j);
                    if (MapEnum.IsDeleteMode)
                    {
                        DeleteModel();
                    }
                    else
                    {
                        AddModel(i, j, worldPos);
                    }
                }
            }
        }
        
        private void AddModel(int row, int column, Vector3 worldPos)
        {
            if (IsNonBuildableLayer(column, row))
            {
                return;
            }
            if(_modelContentDict.TryGetValue(MapEnum.ChunkMode, out var value))
            {
                
                var tempModelNode = Instantiate(_modelNode, value);
                var tempNode = tempModelNode.GetComponent<ModelNode>();
                tempNode.Init(row, column, worldPos);
                tempModelNode.name = _str.ToString();
                if (_modelNodeDict[MapEnum.ChunkMode].ContainsKey(_str.ToString()))
                {
                    _modelNodeDict[MapEnum.ChunkMode][_str.ToString()].Add(tempNode);
                }
                else
                {
                    _modelNodeDict[MapEnum.ChunkMode].Add(_str.ToString(), new List<ModelNode> { tempNode });
                }
            }
            else
            {
                var tempMapContainer  = Instantiate(_modelContainer, transform);
                _modelContentDict.Add(MapEnum.ChunkMode, tempMapContainer);
                _modelNodeDict.Add(MapEnum.ChunkMode, new Dictionary<string, List<ModelNode>>());
                MapManager.SetCurChunkLayer(tempMapContainer.gameObject);
                var tempModelNode = Instantiate(_modelNode, _modelContentDict[MapEnum.ChunkMode]);
                var tempNode = tempModelNode.GetComponent<ModelNode>();
                tempNode.Init(row, column, worldPos);  
                tempModelNode.name = _str.ToString();
                _modelNodeDict[MapEnum.ChunkMode][_str.ToString()] = new List<ModelNode> { tempNode };
                tempMapContainer.gameObject.SetActive(true);
                tempMapContainer.name = MapEnum.ChunkMode;
            }
        }

        private void DeleteModel()
        {
            if (!_modelNodeDict.ContainsKey(MapEnum.ChunkMode) || !_modelNodeDict[MapEnum.ChunkMode].ContainsKey(_str.ToString())) return;
            foreach (var value in _modelNodeDict[MapEnum.ChunkMode][_str.ToString()])
            {
                value.DeleteMe();
            }
            _modelNodeDict[MapEnum.ChunkMode].Remove(_str.ToString());
        }

        public void UpdateMap(int row, int column)
        {
            CleanMap();
            LoadMapData();
        }
        
        private void UpdateMapNodeInfo(int row, int column)
        {
            _str2.Clear();
            _str2.Append("地块坐标：");
            _str2.Append(column).Append("，").Append(row);
            _str2.Append("   拥有：");
            _str.Clear();
            _str.Append(column).Append("_").Append(row);
            foreach (var modelLayer in _modelNodeDict)
            {
                if(modelLayer.Value.ContainsKey(_str.ToString()))
                {
                    _str2.Append(modelLayer.Key).Append("  ");
                }
            }
            _str2.Append("模型");
            MapManager.SetInspectorLabelText2(_str2.ToString());
        }

        public void ChangeLayerState(bool isShow)
        {
            var trs = transform.Find(MapEnum.ChunkMode);
            trs.gameObject.SetActive(isShow);
        }
        
        public void SaveMapData(ref List<string> strList)
        {
            strList.Add("DataModelMap.ModelList = {");
            foreach (var modelPar in _modelNodeDict)
            {
                var index = 1;
                strList.Add($"    [\"{modelPar.Key}\"] = {{");
                foreach (var modelList in modelPar.Value)
                {
                    foreach (var modelNode in modelList.Value)
                    {
                        var pos = modelNode.GetSavePosition();
                        var list = modelList.Key.Split('_');
                        strList.Add($"        [{index}] = {{ modelName = {{ \"{modelNode.GetModelName()}\"}}, coordinate = {{ {list[0]}, {list[1]} }}, pos = {{ {pos.x}, {pos.y} }} }},");
                        index += 1;
                    }
                }
                strList.Add("    },\n");
            }
            strList.Add("}\n");
        }
        
        public void SaveMapData2(ref List<string> strList)
        {
            strList.Add("        private static Dictionary<string, List<ModelData>> _modelNodeDict;\n");
            strList.Add("        public struct ModelData\n        {\n            public int CoordinateX;\n            public int CoordinateY;\n            public int PosX;\n            public int PosY;\n            public string Layer;\n            public int ResourcesId;\n            public ModelData(int coordinateX, int coordinateY, int posX, int posY, string layer, int resourcesId)\n            {\n                CoordinateX = coordinateX;\n                CoordinateY = coordinateY;\n                PosX = posX;\n                PosY = posY;\n                Layer = layer;\n                ResourcesId = resourcesId;\n            }\n        }");
            strList.Add("        public static void InitModelData()\n        {\n            _modelNodeDict = new Dictionary<string, List<ModelData>>();\n");
            strList.Add("            ModelData modelData;");
            foreach (var modelPar in _modelNodeDict)
            {
                strList.Add($"            _modelNodeDict.Add(\"{modelPar.Key}\", new List<ModelData>());");
                foreach (var modelList in modelPar.Value)
                {
                    foreach (var modelNode in modelList.Value)
                    {
                        var pos = modelNode.GetSavePosition();
                        var list = modelList.Key.Split('_');
                        strList.Add($"            modelData = new ModelData({list[0]}, {list[1]}, {pos.x}, {pos.y}, \"{modelPar.Key}\", {modelNode.GetResId()});");
                        strList.Add($"            _modelNodeDict[\"{modelPar.Key}\"].Add(modelData);");
                    }
                }
            }
            strList.Add("        }\n");
            strList.Add("\n        public static Dictionary<string, List<ModelData>> GetModelDirection()\n        {\n            return _modelNodeDict;\n        }");
        }
        
        private void LoadMapData()
        {
            ModelMapData.InitModelData();
            var chunkDataDict = ModelMapData.GetModelDirection();
            foreach (var chunkDataList in chunkDataDict)
            {
                foreach (var chunkData in chunkDataList.Value)
                {
                    MapEnum.ChangeResourcesName(chunkData.ResourcesId);
                    _str.Clear();
                    _str.Append(chunkData.CoordinateX).Append("_").Append(chunkData.CoordinateY);
                    AddModel(chunkData.CoordinateX, chunkData.CoordinateY, new Vector3(chunkData.PosX / 100, chunkData.PosY / 100, 0));
                }
            }
        }
        
        public void CleanMap(bool isOnlyCurLayer = false)
        {
            if (isOnlyCurLayer)
            {
                if (!_modelNodeDict.TryGetValue(MapEnum.ChunkMode, out var value))
                {
                    Debug.Log($"当前地图层没有数据");
                    return;
                }
                foreach (var modelList in value)
                {
                    foreach (var modelNode in modelList.Value)
                    {
                        modelNode.DeleteMe();
                    }
                    modelList.Value.Clear();
                }
                _modelNodeDict[MapEnum.ChunkMode].Clear();
            }
            else
            {
                foreach (var modelPar in _modelNodeDict)
                {
                    foreach (var modelList in modelPar.Value)
                    {
                        foreach (var modelNode in modelList.Value)
                        {
                            modelNode.DeleteMe();
                        }
                        modelList.Value.Clear();
                    }
                    modelPar.Value.Clear();
                }
            }
            Debug.Log("清理完成");
        }
        
        private bool IsNonBuildableLayer(int column, int row)
        {
            var config = WorldMap.GetModelConfigById(MapEnum.ResourcesId);
            var list = config.Position.Split(',');
            if ((column + int.Parse(list[0])) > Mathf.Floor(MapEnum.MapWidth / MapEnum.CellSize)
                || (row + int.Parse(list[1])) > Mathf.Floor(MapEnum.MapHeight / MapEnum.CellSize))
            {
                return true;
            }
            for (var i = column; i < column + (int.Parse(list[0])); i++)
            {
                for (var j = row; j < row + (int.Parse(list[1])); j++)
                {
                    if (!_worldMap.CheckChunkIsAvailable(i, j))
                    {
                        return true;
                    }
                }
            }
            if (config.IsLogic == "是") return false;
            MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.NonBuildableLayer);
            for (var i = column; i < column + (int.Parse(list[0])); i++)
            {
                for (var j = row; j < row + (int.Parse(list[1])); j++)
                {
                    _worldMap.AddChunk(i, j);
                }
            }
            MapEnum.ChangeResourcesByName(config.Name);
            return false;
        }
    }
}

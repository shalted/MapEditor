using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Text;
using Script.Map;
using UnityEngine;

namespace Script.Chunk
{
    [SuppressMessage("ReSharper", "PossibleLossOfFraction")]
    public class ChunkTree : MonoBehaviour
    {
        // Start is called before the first frame update
        private Transform _chunkContainer;
        private Transform _chunkNode;
        private StringBuilder _str;
        private StringBuilder _str2;
        private WorldMap _worldMap;
        private Dictionary<string, Transform> _chunkContentDict;
        private Dictionary<string, Dictionary<string, ChunkNode>> _chunkNodeDict;
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
        
        }

        public void Init(WorldMap worldMap)
        {
            _worldMap = worldMap;
            _str = new StringBuilder(200);
            _str2 = new StringBuilder(2000);
            _chunkContentDict = new Dictionary<string, Transform>();
            _chunkNodeDict = new Dictionary<string, Dictionary<string, ChunkNode>>();
            _chunkContainer = transform.Find("ChunkContainer");
            _chunkNode = transform.Find("ChunkNode");
            LoadMapData();
        }
        
        public void AddNode(Vector3 worldPos)
        {
            var column = (int)Mathf.Floor((MapEnum.MapWidth / (2 * MapEnum.Ppu) + worldPos.x) / (MapEnum.CellSize / (float)MapEnum.Ppu));
            var row = (int)Mathf.Floor((MapEnum.MapHeight / (2 * MapEnum.Ppu) + worldPos.y) / (MapEnum.CellSize / (float)MapEnum.Ppu));
            UpdateMapNodeInfo(row, column);
            if (!MapEnum.IsEditorMode || !MapManager.GetCurChunkShowState("ChunkTree")) return;
            ChangeChunk(row, column);
        }
        
        private void ChangeChunk(int row, int column)
        {
            var brushSize = MapEnum.BrushSize;
            for (var i = row - brushSize; i <= row + brushSize; i++)
            {
                for (var j = column - brushSize; j <= column + brushSize; j++)
                {
                    _str.Clear();
                    _str.Append(j).Append("_").Append(i);
                    if (MapEnum.IsDeleteMode)
                    {
                        DeleteChunk();
                    }
                    else
                    {
                        AddChunk(j, i);
                    }
                }
            }
        }
        
        public void AddChunk(int column, int row, bool isRefresh = false)
        {
            if (isRefresh)
            {
                _str.Clear();
                _str.Append(column).Append("_").Append(row);
            }
            if(_chunkContentDict.TryGetValue(MapEnum.ChunkMode, out var value))
            {
                if (_chunkNodeDict[MapEnum.ChunkMode].ContainsKey(_str.ToString())) return;
                var tempChunkNode = Instantiate(_chunkNode, value);
                var tempNode = tempChunkNode.GetComponent<ChunkNode>();
                tempNode.Init(row, column);
                _chunkNodeDict[MapEnum.ChunkMode].Add(_str.ToString(), tempNode);
            }
            else
            {
                var tempMapContainer  = Instantiate(_chunkContainer, transform);
                _chunkContentDict.Add(MapEnum.ChunkMode, tempMapContainer);
                _chunkNodeDict.Add(MapEnum.ChunkMode, new Dictionary<string, ChunkNode>());
                MapManager.SetCurChunkLayer(tempMapContainer.gameObject);
                var tempChunkNode = Instantiate(_chunkNode, _chunkContentDict[MapEnum.ChunkMode]);
                var tempNode = tempChunkNode.GetComponent<ChunkNode>();
                tempNode.Init(row, column);
                _chunkNodeDict[MapEnum.ChunkMode].Add(_str.ToString(), tempNode);
                tempMapContainer.gameObject.SetActive(true);
                tempMapContainer.name = MapEnum.ChunkMode;
            }
        }

        private void DeleteChunk()
        {
            if (!_chunkNodeDict.ContainsKey(MapEnum.ChunkMode) || !_chunkNodeDict[MapEnum.ChunkMode].ContainsKey(_str.ToString())) return;
            _chunkNodeDict[MapEnum.ChunkMode][_str.ToString()].DeleteMe();
            _chunkNodeDict[MapEnum.ChunkMode].Remove(_str.ToString());
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
            _str2.Append("   隶属于：");
            _str.Clear();
            _str.Append(column).Append("_").Append(row);
            foreach (var chunkLayer in _chunkNodeDict)
            {
                if(chunkLayer.Value.ContainsKey(_str.ToString()))
                {
                    _str2.Append(chunkLayer.Key).Append("  ");
                }
            }
            _str2.Append("地块");
            MapManager.SetInspectorLabelText1(_str2.ToString());
        }

        public void ChangeLayerState(bool isShow)
        {
            var trs = transform.Find(MapEnum.ChunkMode);
            trs.gameObject.SetActive(isShow);
        }
        
        public void SaveMapData(ref List<string> strList)
        {
            strList.Add("MapChunkData.ChunkList = {");
            foreach (var chunkPar in _chunkNodeDict)
            {
                var index = 1;
                strList.Add($"    [\"{chunkPar.Key}\"] = {{");
                foreach (var chunk in chunkPar.Value)
                {
                    var pos = chunk.Value.GetSavePosition();
                    var list = chunk.Key.Split('_');
                    strList.Add($"        [{index}] = {{ layerName = {{ \"{chunk.Value.GetSaveLayer()}\" }}, coordinate = {{ {list[0]}, {list[1]} }}, pos = {{ {pos.x}, {pos.y} }} }},");
                    index += 1;
                }
                strList.Add("    },\n");
            }
            strList.Add("}\n");
        }
        
        public void SaveMapData2(ref List<string> strList)
        {
            strList.Add("        private static Dictionary<string, List<ChunkData>> _chunkNodeDict;\n");
            strList.Add("        public struct ChunkData\n        {\n            public int CoordinateX;\n            public int CoordinateY;\n            public int PosX;\n            public int PosY;\n            public string Layer;\n            public ChunkData(int coordinateX, int coordinateY, int posX, int posY, string layer)\n            {\n                CoordinateX = coordinateX;\n                CoordinateY = coordinateY;\n                PosX = posX;\n                PosY = posY;\n                Layer = layer;\n            }\n        }");
            strList.Add("        public static void InitChunkData()\n        {\n            _chunkNodeDict = new Dictionary<string, List<ChunkData>>();\n");
                strList.Add("            ChunkData chunkData;");
            foreach (var chunkPar in _chunkNodeDict)
            {
                strList.Add($"            _chunkNodeDict.Add(\"{chunkPar.Key}\", new List<ChunkData>());");
                foreach (var chunk in chunkPar.Value)
                {
                    var pos = chunk.Value.GetSavePosition();
                    var list = chunk.Key.Split('_');
                    strList.Add($"            chunkData = new ChunkData({list[0]}, {list[1]}, {pos.x}, {pos.y}, \"{chunkPar.Key}\");");
                    strList.Add($"            _chunkNodeDict[\"{chunkPar.Key}\"].Add(chunkData);");
                }
            }
            strList.Add("        }\n");
            strList.Add("\n        public static Dictionary<string, List<ChunkData>> GetChunkDirection()\n        {\n            return _chunkNodeDict;\n        }");
        }

        private void LoadMapData()
        {
            ChunkMapData.InitChunkData();
            var chunkDataDict = ChunkMapData.GetChunkDirection();
            foreach (var chunkDataList in chunkDataDict)
            {
                MapEnum.ChangeCurrentLayerByName(chunkDataList.Key);
                foreach (var chunkData in chunkDataList.Value)
                {
                    _str.Clear();
                    _str.Append(chunkData.CoordinateX).Append("_").Append(chunkData.CoordinateY);
                    AddChunk(chunkData.CoordinateX, chunkData.CoordinateY);
                }
            }
        }
        
        public void CleanMap(bool isOnlyCurLayer = false)
        {
            if (isOnlyCurLayer)
            {
                if (!_chunkNodeDict.TryGetValue(MapEnum.ChunkMode, out var value))
                {
                    Debug.Log($"当前地图层没有数据");
                    return;
                }
                foreach (var chunk in value)
                {
                    chunk.Value.DeleteMe();
                }
                _chunkNodeDict[MapEnum.ChunkMode].Clear();
            }
            else
            {
                foreach (var chunkPar in _chunkNodeDict)
                {
                    foreach (var chunk in chunkPar.Value)
                    {
                        chunk.Value.DeleteMe();
                    }
                    chunkPar.Value.Clear();
                }
            }
        }
        
        public bool CheckChunkIsAvailable(int column, int row)
        {
            var chunkPoint = new StringBuilder(20);
            chunkPoint.Append(column).Append("_").Append(row);
            _chunkNodeDict.TryGetValue(MapEnum.GetChunkLayerById((int)MapEnum.ChunkNameEnum.NonBuildableLayer), out var value);
            if (value != null)
            {
                return !value.ContainsKey(chunkPoint.ToString());
            }
            return true;
        }
    }
}

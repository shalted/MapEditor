using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Text;
using Script.Map;
using Script.Area;
using Script.Model;
using UnityEngine;

namespace Script.Area
{
    [SuppressMessage("ReSharper", "PossibleLossOfFraction")]
    public class AreaTree : MonoBehaviour
    {
        // Start is called before the first frame update
        private Transform _areaContainer;
        private Transform _areaNode;
        private StringBuilder _str;
        private StringBuilder _str2;
        Dictionary<string, Transform> _areaContentDict;
        Dictionary<string, Dictionary<string, AreaNode>> _areaNodeDict;
        private WorldMap _worldMap;
        
        public void Init(WorldMap worldMap)
        {
            _worldMap = worldMap;
            _str = new StringBuilder(200);
            _str2 = new StringBuilder(2000);
            _areaContentDict = new Dictionary<string, Transform>();
            _areaNodeDict = new Dictionary<string, Dictionary<string, AreaNode>>();
            _areaContainer = transform.Find("AreaContainer");
            _areaNode = transform.Find("AreaNode");
            LoadMapData();
        }
        
        public void AddNode(Vector3 worldPos)
        {
            var column = (int)Mathf.Floor((MapEnum.MapWidth / (2 * MapEnum.Ppu) + worldPos.x) / (MapEnum.CellSize / (float)MapEnum.Ppu));
            var row = (int)Mathf.Floor((MapEnum.MapHeight / (2 * MapEnum.Ppu) + worldPos.y) / (MapEnum.CellSize / (float)MapEnum.Ppu));
            if (!MapEnum.IsEditorMode || !MapManager.GetCurChunkShowState("AreaTree")) return;
            if (string.IsNullOrEmpty(MapEnum.AreaName))
            {
                Debug.Log("当前所选区域为空，请选择区域后绘制~");
                return;
            }
            ChangeArea(row, column, worldPos);
        }
        
        private void ChangeArea(int row, int column, Vector3 worldPos)
        {
            const int brushSize = 0;
            for (var i = row - brushSize; i <= row + brushSize; i++)
            {
                for (var j = column - brushSize; j <= column + brushSize; j++)
                {
                    _str.Clear();
                    _str.Append(j).Append("_").Append(i);
                    foreach (var area in _areaNodeDict.Where(area => area.Value.ContainsKey(_str.ToString())))
                    {
                        Debug.Log($"当前位置已有地块, 当前地块属于{area.Value[_str.ToString()].GetAreaName()}");
                        return;
                    }
                    if (MapEnum.IsDeleteMode)
                    {
                        DeleteArea();
                    }
                    else
                    {
                        AddArea(i, j, worldPos);
                    }
                }
            }
        }
        
        private void AddArea(int row, int column, Vector3 worldPos)
        {
            if(_areaContentDict.TryGetValue(MapEnum.AreaName, out var value))
            {
                
                var tempAreaNode = Instantiate(_areaNode, value);
                var tempNode = tempAreaNode.GetComponent<AreaNode>();
                tempNode.Init(row, column);
                tempAreaNode.name = _str.ToString();
                _areaNodeDict[MapEnum.AreaName].Add(_str.ToString(), tempNode);
            }
            else
            {
                var tempMapContainer  = Instantiate(_areaContainer, transform);
                _areaContentDict.Add(MapEnum.AreaName, tempMapContainer);
                _areaNodeDict.Add(MapEnum.AreaName, new Dictionary<string, AreaNode>());
                var tempAreaNode = Instantiate(_areaNode, _areaContentDict[MapEnum.AreaName]);
                var tempNode = tempAreaNode.GetComponent<AreaNode>();
                tempNode.Init(row, column);  
                tempAreaNode.name = _str.ToString();
                _areaNodeDict[MapEnum.AreaName].Add(_str.ToString(), tempNode);
                tempMapContainer.name = MapEnum.AreaName;
                tempMapContainer.gameObject.SetActive(true);
            }
        }

        private void DeleteArea()
        {
            if (!_areaNodeDict.ContainsKey(MapEnum.AreaName) || !_areaNodeDict[MapEnum.AreaName].ContainsKey(_str.ToString())) return;
            _areaNodeDict[MapEnum.AreaName][_str.ToString()].DeleteMe();
            _areaNodeDict[MapEnum.AreaName].Remove(_str.ToString());
        }

        public void UpdateMap(int row, int column)
        {
            CleanMap();
            LoadMapData();
        }
        
        private void LoadMapData()
        {
            // AreaMapData.InitAreaData();
            // var chunkDataDict = AreaMapData.GetAreaDirection();
            // foreach (var chunkDataList in chunkDataDict)
            // {
            //     foreach (var chunkData in chunkDataList.Value)
            //     {
            //         MapEnum.ChangeResourcesName(chunkData.ResourcesId);
            //         _str.Clear();
            //         _str.Append(chunkData.CoordinateX).Append("_").Append(chunkData.CoordinateY);
            //         AddArea(chunkData.CoordinateX, chunkData.CoordinateY, new Vector3(chunkData.PosX / 100, chunkData.PosY / 100, 0));
            //     }
            // }
        }
        
        public void CleanMap(bool isOnlyCurLayer = false)
        {
            if (isOnlyCurLayer)
            {
                if (!_areaNodeDict.TryGetValue(MapEnum.AreaName, out var value))
                {
                    Debug.Log($"当前地图层没有数据");
                    return;
                }
                foreach (var modelList in value)
                {
                    modelList.Value.DeleteMe();
                }
                _areaNodeDict[MapEnum.AreaName].Clear();
            }
            else
            {
                foreach (var modelPar in _areaNodeDict)
                {
                    foreach (var modelList in modelPar.Value)
                    {
                        modelList.Value.DeleteMe();
                    }
                    modelPar.Value.Clear();
                }
            }
            Debug.Log("清理完成");
        }
        
        public bool IsAreaLayer(int column, int row)
        {
            _str.Clear();
            _str.Append(column).Append("_").Append(row);
            Debug.Log(_str);
            return _areaNodeDict.Where(area => area.Value.ContainsKey(_str.ToString())).Any();
        }
    }
}

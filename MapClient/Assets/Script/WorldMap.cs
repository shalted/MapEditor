using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using Script.Chunk;
using Script.Map;
using Script.Model;
using UnityEngine;
using UnityEngine.EventSystems;

namespace Script
{
    [SuppressMessage("ReSharper", "PossibleLossOfFraction")]
    public class WorldMap:MonoBehaviour, IPointerClickHandler, IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        private static Camera _mapCamera;
        private MapTree _mapTree;
        private ChunkTree _chunkTree;
        private ModelTree _modelTree;
        private MapMain _mapMain;
        private GameObject _gameObject;
        private Camera _cameraComp;
        
        private List<string> _stringList;
        private static Dictionary<int, ExcelRow> _excelRowList;

        private const float ScrollSensitivity = 6f;

        private bool _isDrag;
        // Start is called before the first frame update
        public void Start()
        {
            var path = Application.dataPath + "/slg_elem_data.xml";
            DataSlgElem.ReadExcelXml(path, ref _excelRowList);
            var mapMain = transform.Find("MapMain");
            var mapTree = transform.Find("MapTree");
            var chunkTree = mapMain.Find("ChunkTree");
            var modelTree = mapMain.Find("ModelTree");
            _cameraComp = transform.Find("mapCamera").GetComponent<Camera>();
            _cameraComp.orthographicSize = MapEnum.ScreenHeight / (2 * (float)MapEnum.Ppu);
            _mapMain = mapMain.GetComponent<MapMain>();
            _mapMain.Init(_cameraComp);
            _mapTree = mapTree.GetComponent<MapTree>();
            _mapTree.Init();
            _chunkTree = chunkTree.GetComponent<ChunkTree>();
            _chunkTree.Init(this);
            _modelTree = modelTree.GetComponent<ModelTree>();
            _modelTree.Init(this);
            AddDelegate();
            MapManager.Init(this);
            MapManager.SetCurChunkLayer(mapTree.gameObject, mapTree.name);
            MapManager.SetCurChunkLayer(chunkTree.gameObject, chunkTree.name);
            MapManager.SetCurChunkLayer(modelTree.gameObject, modelTree.name);
        }
        
        private void AddDelegate()
        {
            _mapMain.OnUpdateMap += _mapTree.UpdateMap;
            _mapMain.OnUpdateMap += _chunkTree.UpdateMap;
            _mapMain.OnUpdateMap += _modelTree.UpdateMap;
            RefreshMap();
        }

        // Update is called once per frame
        public void RefreshMap()
        {
            _mapMain.FormatPanelData();
            _mapTree.UnInit();
            _mapMain.UpdateMap();
        }
        
        public static Camera GetMapCamera()
        {
            return _mapCamera;
        }
        
        public void OnPointerClick(PointerEventData eventData)
        {
            if (_isDrag)
            {
                return;
            }
            var worldPos = GetClickWorldPosition(eventData);
            if (MapEnum.IsDrawChunk)
            {
                _chunkTree.AddNode(worldPos);
            }
            else
            {
                _modelTree.AddNode(worldPos);
            }
        }
        
        private Vector3 GetClickWorldPosition(PointerEventData eventData)
        {
            if (eventData.pointerCurrentRaycast.gameObject == null)
            {
                return Vector3.one * 100000;
            }
            // 3D 对象获取方式
            return eventData.pointerCurrentRaycast.gameObject != null ? eventData.pointerCurrentRaycast.worldPosition : _mapCamera.ScreenToWorldPoint(eventData.position);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (MapEnum.IsDragDrawMode)
            {
                var worldPos = GetClickWorldPosition(eventData);
                if (worldPos == Vector3.one * 100000)
                {
                    return;
                }
                if (MapEnum.IsDrawChunk)
                {
                    _chunkTree.AddNode(worldPos);
                }
            }
            else
            {
                _mapMain.OnDrag(eventData);
            }
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            _isDrag = true;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            _isDrag = false;
        }

        public void Update()
        {
            OnScrollWheelUpdate();
        }

        // ReSharper disable Unity.PerformanceAnalysis
        private void OnScrollWheelUpdate()
        {
            var scrollValue = Input.GetAxis("Mouse ScrollWheel");
            if (scrollValue == 0) return;
            _cameraComp.orthographicSize = Mathf.Clamp(_cameraComp.orthographicSize + scrollValue * -ScrollSensitivity, 5, 30);
        }
        
        public void CleanChunk()
        {
            _chunkTree.CleanMap(true);
        }
        
        public void CleanModel()
        {
            _modelTree.CleanMap(true);
        }
        
        public void CleanMap()
        {
            _chunkTree.CleanMap();
            _modelTree.CleanMap();
        }
        
        public void SaveDataToFile()
        {
            _stringList = new List<string> { "MapChunkData = MapChunkData or {}\n" };
            _chunkTree.SaveMapData(ref _stringList);
            var luaFilePath = Application.dataPath + @"\Script\Map\MapChunkData.lua";  
            var luaContent = string.Join(Environment.NewLine, _stringList);  
            File.WriteAllText(luaFilePath, luaContent);  
            _stringList.Clear();
            _stringList = new List<string> { "DataModelMap = DataModelMap or {}\n" };
            _modelTree.SaveMapData(ref _stringList);
            luaFilePath = Application.dataPath + @"\Script\Map\DataModelMap.lua";
            luaContent = string.Join(Environment.NewLine, _stringList);  
            File.WriteAllText(luaFilePath, luaContent);  
            _stringList.Clear();
        }
        
        public void SaveDataToFile2()
        {
            SaveChunkMapData();
            SaveModelMapData();
        }
        
        public void SaveChunkMapData()
        {
            _stringList = new List<string> { "using System.Collections.Generic;\n\nnamespace Script.Map\n{\n    public static class ChunkMapData\n    {\n" };
            _chunkTree.SaveMapData2(ref _stringList);
            //_modelTree.SaveMapData2(ref _stringList);
            _stringList.Add("    }\n}");
            var luaFilePath = Application.dataPath + @"\Script\Map\ChunkMapData.cs";  
            var luaContent = string.Join(Environment.NewLine, _stringList);  
            File.WriteAllText(luaFilePath, luaContent);  
            _stringList.Clear();
        }
        
        public void SaveModelMapData()
        {
            _stringList = new List<string> { "using System.Collections.Generic;\n\nnamespace Script.Map\n{\n    public static class ModelMapData\n    {\n" };
            _modelTree.SaveMapData2(ref _stringList);
            _stringList.Add("    }\n}");
            var luaFilePath = Application.dataPath + @"\Script\Map\ModelMapData.cs";  
            var luaContent = string.Join(Environment.NewLine, _stringList);  
            File.WriteAllText(luaFilePath, luaContent);  
            _stringList.Clear();
        }

        public static ExcelRow GetModelConfigById(int id)
        {
            return _excelRowList.GetValueOrDefault(id);
        }
        
        
        public bool CheckChunkIsAvailable(int column, int row)
        {
            return _chunkTree.CheckChunkIsAvailable(column, row);
        }
        
        public void AddChunk(int column, int row)
        {
            _chunkTree.AddChunk(column, row, true);
        }
    }
}
using Script.Map;
using UnityEngine;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public delegate void ChoiceDelegate(string message, bool isShow = true);
    public delegate void BollDelegate(bool isTrue);
    public class MapPanelClass:BaseLineClass
    {
        private Toggle _isShowMapPanel;
        private Toggle _isDynamicLoading;
        private Toggle _isShowMapLine;
        private Toggle _isEditorMode;

        private TextField _folderTextField;
        private TextField _mapWidthField;
        private TextField _maoHeightField;
        private TextField _mapCellWidthField;
        private TextField _mapCellHeightField;
        private TextField _mapChunkSizeField;

        public void CreateMapLine(VisualElement parentElement)
        {
            
            var line = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Column,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#4F4F4F")),
                    height = 120, // 设置固定高,
                }
            };
            CreateTitleLine(line);
            parentElement.Add(line);
        }

        private void CreateTitleLine(VisualElement parentElement)
        {
            CreateTitle(parentElement);
            CreateBtnList1(parentElement);
            CreateBtnList2(parentElement);
        }

        private void CreateTitle(VisualElement parentElement)
        {
            var line = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Row,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#4F4F4F")),
                    height = 30, // 设置固定高,
                    marginTop = 15,
                    marginLeft = 10,
                }
            };
            CreateCommonLabel(line, "地图层", 20, true);
            CreateCommonToggle(line, "是否显示", out _isShowMapPanel, OnclickPanelShow);
            CreateCommonToggle(line, "是否编辑模式", out _isEditorMode, ChangeEditorMode);
            _isShowMapPanel.value = true;
            _isEditorMode.value = MapEnum.IsEditorMode;
            parentElement.Add(line);
        }
        
        private void CreateBtnList1(VisualElement parentElement)
        {
            var line = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Row,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#4F4F4F")),
                    height = 30, // 设置固定高,
                }
            };
            CreateTextFieldCommonLine(line, "文件夹：", out _folderTextField);
            CreateTextFieldCommonLine(line, "地图宽：", out _mapWidthField);
            CreateTextFieldCommonLine(line, "地图高：", out _maoHeightField);
            CreateTextFieldCommonLine(line, "地图块宽：", out _mapCellWidthField);
            CreateTextFieldCommonLine(line, "地图块高：", out _mapCellHeightField);
            CreateTextFieldCommonLine(line, "格子大小：", out _mapChunkSizeField);
            parentElement.Add(line);
        }
        
        private void CreateBtnList2(VisualElement parentElement)
        {
            var line = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Row,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#4F4F4F")),
                    height = 30, // 设置固定高,
                }
            };
            CreateCommonToggle(line, "是否加载全地图", out _isDynamicLoading, OnclickChangeLoadMode);
            CreateCommonToggle(line, "是否显示网格线", out _isShowMapLine, OnclickChangeMeshMode);
            CreateCommonBtn(line, "刷新", OnclickRefresh, true);
            _isDynamicLoading.value = MapEnum.IsLoadAllMap;
            _isShowMapLine.value = MapEnum.IsShowMeshMode;
            parentElement.Add(line);
        }

        private void OnclickRefresh()
        {
            MapEnum.IsLoadAllMap = _isDynamicLoading.value;
            MapEnum.MapName = string.IsNullOrEmpty(_folderTextField.text) ? MapEnum.MapName : _folderTextField.text;
            TryParseField(_mapWidthField, out var width,"当前地图宽度输入为空，请确认");
            TryParseField(_maoHeightField, out var height,"当前地图高度输入为空，请确认");
            TryParseField(_mapCellWidthField, out var nodeWidth,"当前地图块宽度输入为空，请确认");
            TryParseField(_mapCellHeightField, out var nodeHeight,"当前地图块高度输入为空，请确认");
            TryParseField(_mapChunkSizeField, out var cellSize,"当前格子大小输入为空，请确认");
            MapEnum.MapWidth = width == 0 ? MapEnum.MapWidth : width;
            MapEnum.MapHeight = height == 0 ? MapEnum.MapHeight : height;
            MapEnum.MapNodeWidth = nodeWidth == 0 ? MapEnum.MapNodeWidth : nodeWidth;
            MapEnum.MapNodeHeight = nodeHeight == 0 ? MapEnum.MapNodeHeight : nodeHeight;
            MapEnum.CellSize = cellSize == 0 ? MapEnum.CellSize : cellSize;
            Debug.Log(MapEnum.MapWidth + " " + MapEnum.MapHeight + " " + MapEnum.MapNodeWidth + " " + MapEnum.MapNodeHeight + " " + MapEnum.CellSize);
            MapManager.RefreshMap();
        }
        
        private void OnclickChangeLoadMode(bool isTrue)
        {
            MapEnum.ChangeLoadAllMap(isTrue);
        } 
        
        private void OnclickChangeMeshMode(bool isTrue)
        {
            MapEnum.ChangeShowMeshMode(isTrue);
        } 
        
        private void OnclickPanelShow(bool isTrue)
        {
            MapManager.SetCurChunkShowState(isTrue, "MapTree");
        } 
        
        private void ChangeEditorMode(bool isTrue)
        {
            MapEnum.IsEditorMode = isTrue;
        } 
        
        private static void TryParseField(TextField field, out int value, string msg)
        {
            if (!int.TryParse(field.text, out value))
            {
                Debug.Log(msg);
            }
        }
    }
}
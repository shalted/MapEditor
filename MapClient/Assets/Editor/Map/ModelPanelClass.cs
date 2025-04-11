using System.Collections.Generic;
using UnityEngine;
using Script.Map;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public class ModelPanelClass:BaseLineClass
    {
        private Toggle _isModel;
        private Toggle _isShowModelLine;
        private Toggle _isShowCurLayer;
        private int _currentLayer;

        private TextField _resourcesName;
        private TextField _resourcesSize;
        private TextField _resourcesPosition;
        
        private readonly List<string> _list = new List<string> { "树", "建筑", "资源" };

        public void CreateModelLine(VisualElement parentElement)
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
            CreateCommonLabel(line, "模型层", 20, true);
            CreateCommonToggle(line, "是否显示", out _isShowModelLine, OnclickPanelShow);
            _isShowModelLine.value = false;
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
            CreateCommonDropdownField(line, "当前层：", _list, OnclickChoose);
            CreateCommonToggle(line, "是否显示当前层", out _isShowCurLayer, OnclickChangeState);
            _isShowCurLayer.value = true;
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
            CreateTextFieldCommonLine(line, "资源名称：", out _resourcesName);
            CreateTextFieldCommonLine(line, "大小：", out _resourcesSize);
            CreateTextFieldCommonLine(line, "地图位置：", out _resourcesPosition);
            CreateCommonBtn(line, "编辑当前层", OnclickSelectEditor, true);
            CreateCommonBtn(line, "清除", OnclickClean);
            CreateCommonBtn(line, "保存", OnclickSave);
            _resourcesSize.RegisterCallback<FocusOutEvent>(evr =>
            {
                OnChangeModelSize();
            });
            _resourcesName.RegisterCallback<FocusOutEvent>(evr =>
            {
                OnChangeModelName();
            });
            parentElement.Add(line);
        }
        
        private void OnclickPanelShow(bool isTrue)
        {
            OnclickChoose(_list[_currentLayer]);
            MapManager.SetCurChunkShowState(isTrue, "ModelTree");
        }
        
        private void OnclickChoose(string chooseStr, bool isChange = true)
        {
            switch (chooseStr) 
            {
                case "树":
                    MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.TreePoint);
                    _currentLayer = 0;
                    break;
                case "建筑":
                    MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.BuildPoint);
                    _currentLayer = 1;
                    break;
                case "资源":
                    MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.ResourcePoint);
                    _currentLayer = 2;
                    break;
            }
            Debug.Log("选择了" + chooseStr);
            if (isChange)
            {
                _isShowCurLayer.value = MapManager.GetCurChunkShowState();
            }
        }

        private void OnclickChangeState(bool isTrue)
        {
            Debug.Log("当前层是否显示" + isTrue);
            MapManager.SetCurChunkShowState(isTrue);
            OnclickChoose(_list[_currentLayer], false);
        }

        private void OnclickRefresh()
        {
            Debug.Log("hello 这里触发了创建");
        }
        
        private void OnclickClean()
        {
            OnclickChoose(_list[_currentLayer], false);
            MapManager.ClearModel();
        }
        
        private void OnclickSave()
        {
            MapManager.SaveModelMap();
        }
        
        private void OnclickSelectEditor()
        {
            OnclickChoose(_list[_currentLayer]);
            _isShowModelLine.value = true;
            MapManager.SetCurChunkShowState(true, "ModelTree");
        }
        
        private void OnChangeModelName()
        {
            OnclickChoose(_list[_currentLayer]);
            MapManager.SetCurChunkShowState(true);
            MapEnum.ChangeResourcesName(int.Parse(_resourcesName.value));
        }
        
        private void OnChangeModelSize()
        {
            MapEnum.ChangeModelSize(int.Parse(_resourcesSize.value));
        }

    }
}
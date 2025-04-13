using System.Collections.Generic;
using Script.Map;
using UnityEngine;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public class ChunkPanelClass:BaseLineClass
    {
        private Toggle _isOpenDragModel;
        private Toggle _isOpenDeleteModel;
        private Toggle _isShowChunkModel;
        private Toggle _isShowCurChunk;

        private int _currentLayer;
        
        private TextField _brushTextField;
        private readonly List<string> _list = new List<string> { "资源层", "出生层", "不可建造层", "怪物层" };

        public void CreateChunkLine(VisualElement parentElement)
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
                    height = 30, // 设置固定高,
                    marginTop = 15,
                    marginLeft = 10,
                }
            };
            CreateCommonLabel(line, "地块层", 20, true);
            CreateCommonToggle(line, "是否显示", out _isShowChunkModel, OnclickPanelShow);
            _isShowChunkModel.value = false;
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
                    height = 30, // 设置固定高,
                }
            };
            CreateCommonDropdownField(line, "当前层：", _list, OnclickChoose);
            CreateCommonToggle(line, "是否显示当前层", out _isShowCurChunk, OnclickChangeState);
            CreateTextFieldCommonLine(line, "笔刷大小：", out _brushTextField);
            _brushTextField.RegisterCallback<FocusOutEvent>(evr =>
            {
                OnBrushChange();
            });
            _isShowCurChunk.value = true;
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
                    height = 30, // 设置固定高,
                }
            };
            CreateCommonToggle(line, "是否启用删除模式", out _isOpenDeleteModel, OnclickChangeDeleteMode);
            CreateCommonToggle(line, "是否启用拖拽涂色", out _isOpenDragModel, OnclickDragDrawMode);
            CreateCommonBtn(line, "编辑当前层", OnclickSelectEditor, true);
            CreateCommonBtn(line, "清除", OnclickClean);
            CreateCommonBtn(line, "保存", OnclickSave);
            parentElement.Add(line);
        }
        
        private void OnclickChoose(string chooseStr, bool isChange = true)
        {
            switch (chooseStr) 
            {
                case "资源层":
                    MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.ResourceLayer);
                    _currentLayer = 0;
                    break;
                case "行走层":
                    MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.WalkableLayer);
                    _currentLayer = 1;
                    break;
                case "不可建造层":
                    MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.NonBuildableLayer);
                    _currentLayer = 2;
                    break;
                case "怪物层":
                    MapEnum.ChangeCurrentLayer((int)MapEnum.ChunkNameEnum.MonsterLayer);
                    _currentLayer = 3;
                    break;
                default:
                    break;
            }
            Debug.Log("选择了" + chooseStr);
            if (isChange)
            {
                _isShowCurChunk.value = MapManager.GetCurChunkShowState();
            }
        }

        private void OnclickPanelShow(bool isTrue)
        {
            OnclickChoose(_list[_currentLayer]);
            MapManager.SetCurChunkShowState(isTrue, "ChunkTree");
        }
        
        private void OnclickChangeState(bool isTrue)
        {
            OnclickChoose(_list[_currentLayer], false);
            MapManager.SetCurChunkShowState(isTrue);
        }
        
        private void OnclickChangeDeleteMode(bool isTrue)
        {
            MapEnum.ChangeDeleteMode(isTrue);
        }
        
        private void OnclickDragDrawMode(bool isTrue)
        {
            MapEnum.ChangeDragDrawMode(isTrue);
        }
        
        private void OnBrushChange()
        {
            MapEnum.ChangeBrushSize(int.Parse(_brushTextField.value));
        }
        
        private void OnclickRefresh()
        {
            Debug.Log("hello 这里触发了刷新");
        }
        
        private void OnclickClean()
        {
            OnclickChoose(_list[_currentLayer], false);
            MapManager.ClearChunk();
        }
        
        private void OnclickSave()
        {
            MapManager.SaveChunkMap();
        }
        
        private void OnclickSelectEditor()
        {
            OnclickChoose(_list[_currentLayer]);
            _isShowChunkModel.value = true;
            MapManager.SetCurChunkShowState(true, "ChunkTree");
        }
        
    }
}
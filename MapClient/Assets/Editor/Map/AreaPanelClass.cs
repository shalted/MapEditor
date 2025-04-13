using System.Collections.Generic;
using UnityEngine;
using Script.Map;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public class AreaPanelClass:BaseLineClass
    {
        private readonly List<string> _areaList = new List<string> {  };
        
        private Toggle _isShowAreaModel;
        private TextField _areaName;
        private string selectArea;
        
        public void CreateAreaLine(VisualElement parentElement)
        {
            
            var line = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Column,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#5c5c5c")),
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
            CreateCommonLabel(line, "区域层", 20, true);
            CreateCommonToggle(line, "是否显示", out _isShowAreaModel, OnclickPanelShow);
            _isShowAreaModel.value = true;
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
            CreateCommonDropdownField(line, "当前区域：", _areaList, OnclickChoose);
            CreateTextFieldCommonLine(line, "添加区域：", out _areaName);
            CreateCommonBtn(line, "确定添加", OnclickCreate);
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
            CreateCommonBtn(line, "编辑当前层", OnclickSelectEditor, true);
            CreateCommonBtn(line, "清除", OnclickClean);
            CreateCommonBtn(line, "保存", OnclickSave);
            parentElement.Add(line);
        }
        
        private void OnclickPanelShow(bool isTrue)
        {
            MapManager.SetCurChunkShowState(isTrue, "AreaTree");
        }
        
        private void OnclickChoose(string chooseStr, bool isChange = true)
        {
            selectArea = chooseStr;
            MapManager.SetCurArea(chooseStr);
        }
        
        private void OnclickCreate()
        {
            if (!string.IsNullOrEmpty(_areaName.value))
            {
                _areaList.Add(_areaName.value);
            }
        }
        
        private void OnclickSelectEditor()
        {
            _isShowAreaModel.value = true;
            MapManager.SetCurChunkShowState(true, "AreaTree");
            MapManager.SetAreaEditor();
        }
        
        private void OnclickClean()
        {
            MapManager.ClearArea(selectArea);
        }
        
        private void OnclickSave()
        {
            
        }
    }
}
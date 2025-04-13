using Script.Map;
using UnityEngine;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public class SpecialFeaturesClass:BaseLineClass
    {
        public void CreateLine(VisualElement parentElement)
        {
            
            var line = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Column,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#4F4F4F")),
                    height = 90, // 设置固定高,
                }
            };
            CreateTitleLine(line);
            parentElement.Add(line);
        }

        private void CreateTitleLine(VisualElement parentElement)
        {
            CreateTitle(parentElement);
            CreateBtnList1(parentElement);
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
            CreateCommonLabel(line, "特殊功能层", 20, true);
            CreateCommonLabel(line, "(这里操作是对所有图层，包含地块和模型)");

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
            CreateCommonBtn(line, "清除地图", OnclickCleanMap, true);
            CreateCommonBtn(line, "保存数据", OnclickSaveMap);
            parentElement.Add(line);
        }
        
        private static void OnclickCleanMap()
        {
            MapManager.ClearMap();
        }
        
        private static void OnclickSaveMap()
        {
            MapManager.SaveMap();
        }
    }
}
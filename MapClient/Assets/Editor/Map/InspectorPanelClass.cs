using Script.Map;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public class InspectorPanelClass:BaseLineClass
    {
        private Label _label;
        private Label _label2;

        public void CreateInspectorLine(VisualElement parentElement)
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
            MapManager.SetInspectorLabel(_label, _label2);
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
            CreateCommonLabel(line, "属性展示", 20, true);
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
            CreateLabelCommonLine(line, "属性列：", out _label);
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
            CreateLabelCommonLine(line, "属性列：", out _label2);
            parentElement.Add(line);
        }
        
    }
}
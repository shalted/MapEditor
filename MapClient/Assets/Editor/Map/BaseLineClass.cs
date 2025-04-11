using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public class BaseLineClass:VisualElement
    {
        private float _value;
        private Vector2 _dragStartPos;
        private float _dragStartValue;
        private bool _isDragging;

        protected static Color HexToColor(string hex)
        {
            // 移除开头的 #
            hex = hex.Replace("#", "");

            // 如果长度不是 6 或 8，抛出异常
            if (hex.Length != 6 && hex.Length != 8)
                throw new ArgumentException("Invalid hex color code");

            // 解析颜色分量
            var r = byte.Parse(hex.Substring(0, 2), System.Globalization.NumberStyles.HexNumber);
            var g = byte.Parse(hex.Substring(2, 2), System.Globalization.NumberStyles.HexNumber);
            var b = byte.Parse(hex.Substring(4, 2), System.Globalization.NumberStyles.HexNumber);
            var a = hex.Length == 8 ? byte.Parse(hex.Substring(6, 2), System.Globalization.NumberStyles.HexNumber) : (byte)255;

            return new Color(r / 255f, g / 255f, b / 255f, a / 255f);
        }
        
        protected static void CreateCommonLabel(VisualElement parentElement, string labelName, int size = 14, bool isTitle = false)
        {
            var temp = new Label
            {
                style =
                {
                    unityTextAlign = TextAnchor.MiddleCenter,
                    marginLeft = 5,
                    fontSize = size,
                },
                text = labelName,
            };
            if (isTitle)
            {
                temp.style.unityFontStyleAndWeight = FontStyle.Bold;
            }
            parentElement.Add(temp);
        }
        
        protected static void CreateTextFieldCommonLine(VisualElement parentElement, string labelName, out TextField textField)
        {
            var temp = new Label
            {
                style =
                {
                    unityTextAlign = TextAnchor.MiddleCenter,
                    marginLeft = 20,
                },
                text = labelName,
            };
            parentElement.Add(temp);
            textField = new TextField
            {
                style =
                {
                    width = 80,
                    height = 20,
                    backgroundColor = new StyleColor(Color.gray),  // 设置背景颜色
                    display = DisplayStyle.Flex,
                    flexDirection = FlexDirection.Column,
                    alignContent = Align.Center,
                    marginLeft = 5,
                    marginTop = 5,
                }
            };
            parentElement.Add(textField);
        }
        
        protected static void CreateCommonBtn(VisualElement parentElement, string btnName, Action callback, bool isRight = false)
        {
            var tempButton = new Button()
            {
                style =
                {
                    marginTop = 2,
                }
            };
            if (isRight)
            {
                tempButton.style.marginLeft = StyleKeyword.Auto;
                tempButton.style.marginRight = 10;
            }
            tempButton.clicked += callback;
            var temp = new Label(btnName)
            {
                style =
                {
                    marginTop = 3,
                    unityTextAlign = TextAnchor.MiddleCenter,
                }
            };
            tempButton.Add(temp);
            parentElement.Add(tempButton);
        }
        
        protected static void CreateCommonToggle(VisualElement parentElement, string toggleName, out Toggle curToggle, BollDelegate callback)
        {
            var temp = new Label
            {
                style =
                {
                    unityTextAlign = TextAnchor.MiddleCenter,
                    marginLeft = 20,
                },
                text = toggleName,
            };
            parentElement.Add(temp);
            curToggle = new Toggle
            {
                style =
                {
                    marginTop = 2,
                }
            };
            curToggle.RegisterValueChangedCallback(evt =>
            {
                callback(evt.newValue);
            });
            parentElement.Add(curToggle);
        }
        
        protected static void CreateCommonDropdownField(VisualElement parentElement, string dropdownFieldName, List<string> choiceList, ChoiceDelegate callback)
        {
            var temp = new Label
            {
                style =
                {
                    unityTextAlign = TextAnchor.MiddleCenter,
                    marginLeft = 20,
                },
                text = dropdownFieldName,
            };
            parentElement.Add(temp);
            var dropdownField = new DropdownField
            {
                style =
                {
                    unityTextAlign = TextAnchor.MiddleCenter,
                    marginLeft = 5,
                },
                choices = choiceList
            };
            dropdownField.RegisterValueChangedCallback(evt =>
            {
                callback(evt.newValue);
            });
            dropdownField.index = 0;
            parentElement.Add(dropdownField);
        }
        
        protected static void CreateLabelCommonLine(VisualElement parentElement, string labelName, out Label label)
        {
            var temp = new Label
            {
                style =
                {
                    unityTextAlign = TextAnchor.MiddleCenter,
                    marginLeft = 20,
                },
                text = labelName,
            };
            parentElement.Add(temp);
            label = new Label
            {
                style =
                {
                    width = 800,
                    height = 20,
                    display = DisplayStyle.Flex,
                    flexDirection = FlexDirection.Column,
                    alignContent = Align.Center,
                    marginLeft = 5,
                    marginTop = 7,
                }
            };
            parentElement.Add(label);
        }
    }
}
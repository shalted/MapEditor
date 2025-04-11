using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UIElements;

namespace Editor.Map
{
    public class TimelineEditorWindow : EditorWindow
    {
        private const string PrefabPath = "Assets/Prefabs/WorldMap.prefab";
        private const string ScriptComponent = "WorldMap"; 
        
        private const float TimelineWidth = 900;
        public const float TimelineTitleWidth = 300;
        private static float _totalTimeInSeconds = 10;
        private const float FrameRate = 60;  // 每秒帧数
        private const float UpdateInterval = 1f / FrameRate; // 更新间隔（30fps）
    
        private VisualElement _root;
        private VisualElement _cursor;
        private VisualElement _timeLineParentRoot;
        private ScrollView _timelineScrollView;
        private bool _isPlaying;
        private float _currentTime;
        private Vector2 _scrollPosition;
        private float _lastUpdateTime; // 上次更新时间
 
        private Button _playPauseButton;
        private Label _timeDisplay;
        private Label _gameObjectText;
        private TextField _timesTextField;
        private AnimationClip _animation;
        private bool _isDragging;
        private Vector2 _dragStartPos;
    
        public static Event Evt;

        [MenuItem("Window/地图编辑器")]
        private static void ShowWindow()
        {
            Evt = Event.current;
            TimelineEditorWindow wnd = GetWindow<TimelineEditorWindow>();
            wnd.titleContent = new GUIContent("地图编辑器");
            wnd.minSize = new Vector2(1200, 800); // 设置固定的最小大小
            wnd.maxSize = new Vector2(1200, 800); // 设置固定的最大大小
            wnd.Show();
        }
    
        private void OnGUI()
        {
            Evt = Event.current;
        }

        public void CreateGUI()
        {
            _root = CreateRoot();
            var parameterInputBox = CreateParameterInputBoxRoot(_root);
            CreateTimesInputTextField(parameterInputBox);
            CreateTimesRefreshBtn(parameterInputBox);
            var timeLineRoot = CreateTimeLine(_root);
            var timeButtonRoot = CreateTimeBtnEle(timeLineRoot);
            _timeLineParentRoot = CreateTimeLineParent(timeLineRoot);
            CreateTimeText(timeButtonRoot);
            CreatePrevBtn(timeButtonRoot);
            CreatePlayBtn(timeButtonRoot);
            CreateNextBtn(timeButtonRoot);
            CreateTimeLineScroll(_timeLineParentRoot);
            var timeLineLongitudinalRoot = CreateScrollViewContent();
            var timeLineHorizontalRoot = CreateScrollViewCursorContent(timeLineLongitudinalRoot);
            CreateTimeLineCursor(timeLineHorizontalRoot);
            CreateTimeLineTimeText(timeLineLongitudinalRoot);
            CreateInspectorPanel();
            CreateMapPanel();
            CreateChunkPanel();
            CreateModelPanel();
            CreateSpecialFeatures();
            //CreateAreaPanelClass();
            CheckAndSpawnPrefab();
            EditorApplication.update += OnEditorUpdate;
        }

        // 创建时间轴节点
        private VisualElement CreateRoot()
        {
            var timeLineRoot = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Column,
                    justifyContent = Justify.FlexStart,
                    height = 40, // 设置固定高度
                    flexGrow = 1f,
                }
            };
            rootVisualElement.Add(timeLineRoot);
            return timeLineRoot;
        }
    
        // 创建输入文本框相关内容
        private static VisualElement CreateParameterInputBoxRoot(VisualElement parentElement)
        {
            var tempRoot = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Row,
                    justifyContent = Justify.Center,  // 水平居中
                    alignItems = Align.Center,
                    height = 40, // 设置固定高度
                    backgroundColor = new StyleColor(Color.black),
                }
            };
            parentElement.Add(tempRoot);
            return tempRoot;
        }
    
        // 创建文本输入框
        private void CreateTimesInputTextField(VisualElement parentElement)
        {
            var temp = new Label
            {
                style =
                {
                    marginLeft = 20,
                },
                text = ($"时间轴长度:"),
            };
            parentElement.Add(temp);
            _timesTextField = new TextField
            {
                style =
                {
                    width = 50,
                    height = 20,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(Color.gray),  // 设置背景颜色
                    unityTextAlign = TextAnchor.MiddleCenter,  // 水平居中
                    marginLeft = 10,
                }
            };
            parentElement.Add(_timesTextField);
        }
    
        // 创建刷新按钮
        private void CreateTimesRefreshBtn(VisualElement parentElement)
        {
            var tempButton = new Button();
            tempButton.clicked += OnclickRefreshBtn;
            var temp = new Label($"刷新");
            tempButton.Add(temp);
            parentElement.Add(tempButton);
        }
    
        // 按钮点击回调
        private void OnclickRefreshBtn()
        {
            Debug.Log(_timesTextField.text);
            _totalTimeInSeconds = int.Parse(_timesTextField.text);
            OnRefreshBtn();
        }
    
        // 点击刷新按钮
        private void OnRefreshBtn()
        {
            _timeLineParentRoot.Clear();
            CreateTimeLineScroll(_timeLineParentRoot);
            var timeLineLongitudinalRoot = CreateScrollViewContent();
            var timeLineHorizontalRoot = CreateScrollViewCursorContent(timeLineLongitudinalRoot);
            CreateTimeLineCursor(timeLineHorizontalRoot);
            CreateTimeLineTimeText(timeLineLongitudinalRoot);
        }

        // 创建时间轴节点
        private static VisualElement CreateTimeLine(VisualElement parentElement)
        {
            var timeLineRoot = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Row,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(Color.black),
                    height = 60, // 设置固定高度
                }
            };
            parentElement.Add(timeLineRoot);
            return timeLineRoot;
        }
    
        // 创建按钮节点
        private static VisualElement CreateTimeBtnEle(VisualElement parentElement)
        {
            var timeButtonRoot = new VisualElement
            {
                style = { 
                    flexDirection = FlexDirection.Row,
                    justifyContent = Justify.Center,  // 水平居中
                    alignItems = Align.Center,
                    backgroundColor = new StyleColor(Color.black),
                    height = 60, // 设置固定高度
                    width = 300, // 设置固定高度
                }
            };
            parentElement.Add(timeButtonRoot);
            return timeButtonRoot;
        }
    
        // 创建timeline父节点
        private static VisualElement CreateTimeLineParent(VisualElement parentElement)
        {
            var lineRoot = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Column,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#8B8B83")),
                    height = 60, // 设置固定高度
                    width = TimelineWidth, // 设置固定高度
                }
            };
            parentElement.Add(lineRoot);
            return lineRoot;
        }
    
        // 添加时间显示文本
        private void CreateTimeText(VisualElement parentElement)
        {
            _timeDisplay = new Label
            {
                text = $"Time: {_currentTime:F2}s",
                style =
                {
                    width = 100,
                    height = 30,
                    backgroundColor = new StyleColor(Color.gray),  // 设置背景颜色
                    unityTextAlign = TextAnchor.MiddleCenter,  // 水平居中
                    justifyContent = Justify.Center,  // 垂直居中
                    marginLeft = 10,
                }
            };
            parentElement.Add(_timeDisplay);
        }
    
        // 创建上一帧按钮
        private void CreatePrevBtn(VisualElement parentElement)
        {
            var previousFrameButton = new Button(PreviousFrame)
            {
                text = "Prev",
                style =
                {
                    width = 40,
                    height = 30,
                    marginLeft = 10,
                }
            };
            parentElement.Add(previousFrameButton);
        }
    
        // 创建播放、暂停按钮
        private void CreatePlayBtn(VisualElement parentElement)
        {
            _playPauseButton = new Button(TogglePlayPause)
            {
                text = "Play",
                style =
                {
                    width = 40,
                    height = 30,
                    marginLeft = 10,
                }
            };
            parentElement.Add(_playPauseButton);
        }
    
        // 创建下一帧按钮
        private void CreateNextBtn(VisualElement parentElement)
        {
            var nextFrameButton = new Button(NextFrame)
            {
                text = "Next",
                style =
                {
                    width = 40,
                    height = 30,
                    marginLeft = 10,
                }
            };
            parentElement.Add(nextFrameButton);
        }

        // 创建滚动条
        private void CreateTimeLineScroll(VisualElement parentElement)
        {
            _timelineScrollView = new ScrollView(ScrollViewMode.Horizontal)
            {
                style =
                {
                    height = 60,
                    backgroundColor = new StyleColor(Color.black),
                },
                horizontalScroller =
                {
                    style ={display = DisplayStyle.None},
                }
            };
            parentElement.Add(_timelineScrollView);
        }
        
        private VisualElement CreateScrollViewContent()
        {
            var lineRoot = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Column,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#8B8B83")),
                    height = 80, // 设置固定高度
                    width = TimelineWidth, // 设置固定高度
                }
            };
            _timelineScrollView.Add(lineRoot);
            return lineRoot;
        }
    
        private static VisualElement CreateScrollViewCursorContent(VisualElement parentElement)
        {
            var lineRoot = new VisualElement
            {
                style =
                {
                    flexDirection = FlexDirection.Row,
                    justifyContent = Justify.FlexStart,
                    backgroundColor = new StyleColor(HexToColor("#8B8B83")),
                    height = 20,// 设置固定高度
                    width = TimelineWidth, // 设置固定高度
                }
            };
            parentElement.Add(lineRoot);
            return lineRoot;
        }
    
        // 创建刻度显示
        private static void CreateTimeLineCursor(VisualElement parentElement)
        {
            for (var i = 0; i < _totalTimeInSeconds; i++)
            {
                var tickMark = new Label
                {
                    text = (i + 1).ToString(),
                    style =
                    {
                        width  = (TimelineWidth / _totalTimeInSeconds),  // 每秒的宽度
                        height = 20,
                        flexDirection = FlexDirection.Column,
                        unityTextAlign = TextAnchor.MiddleCenter,
                        backgroundColor = i % 2 == 0 ? new StyleColor(HexToColor("#4F4F4F")) : new StyleColor(HexToColor("#5c5c5c")),
                    }
                };
                parentElement.Add(tickMark);
            }
        }
    
        // 创建游标
        private void CreateTimeLineTimeText(VisualElement parentElement)
        {
            _cursor = new VisualElement
            {
                style =
                {
                    width = 2,
                    height = 20,
                    flexDirection = FlexDirection.Column,
                    backgroundColor = Color.white,
                    alignItems = Align.Center,
                }
            };
            parentElement.Add(_cursor);
        }
    
        private void OnDisable()
        {
            Debug.Log("Window is being disabled or closed.");
            _isPlaying = false;
        }
    
        // 播放与暂停状态值
        private void TogglePlayPause()
        {
            _isPlaying = !_isPlaying;
            if (_isPlaying)
            {
                AnimationMode.StartAnimationMode();
            }
            else
            {
                Debug.Log("关闭动作播放：");
                AnimationMode.StopAnimationMode();
            }
            _playPauseButton.text = _isPlaying ? "Pause" : "Play";
        }
    
        // 编辑器更新
        private void OnEditorUpdate()
        {
            if (!_isPlaying) return;
            PlayTime();
        }
    
        // 游标与时间显示更新
        private void PlayTime()
        {
            var currentTimeInEditor = Time.realtimeSinceStartup;
            // 检查是否需要更新
            if (currentTimeInEditor - _lastUpdateTime >= UpdateInterval)
            {
                _lastUpdateTime = currentTimeInEditor;

                // 更新当前时间
                _currentTime += UpdateInterval;
                if (_currentTime >= _totalTimeInSeconds)
                {
                    _currentTime = 0; // 循环播放
                }

                // 更新游标位置
                var normalizedTime = _currentTime / _totalTimeInSeconds;
                var newLeft = normalizedTime * TimelineWidth; // 时间轴宽度
                _cursor.style.left = newLeft;
            }
            _timeDisplay.text = $"Time: {_currentTime:F2}s";
        }

        // 更新当前游标位置
        private void UpdateCursor()
        {
            var normalizedTime = _currentTime / _totalTimeInSeconds;
            var newLeft = normalizedTime * TimelineWidth;
            _cursor.style.left = newLeft; 
            _timeDisplay.text = $"Time: {_currentTime:F2}s";
        }

        // 游标移动到上一帧
        private void PreviousFrame()
        {
            _currentTime = Mathf.Max(0, _currentTime - UpdateInterval);
            AnimationMode.StartAnimationMode();
            UpdateCursor();
        }

        // 游标移动到下一帧
        private void NextFrame()
        {
            _currentTime = Mathf.Min(_totalTimeInSeconds, _currentTime + UpdateInterval);
            AnimationMode.StartAnimationMode();
            UpdateCursor();
        }

        // 创建地图编辑区域
        private void CreateMapPanel()
        {
            var mapLine = new MapPanelClass();
            mapLine.CreateMapLine(_root);
        }
        private void CreateChunkPanel()
        {
            var chunkLine = new ChunkPanelClass();
            chunkLine.CreateChunkLine(_root);
        }
        private void CreateModelPanel()
        {
            var modelLine = new ModelPanelClass();
            modelLine.CreateModelLine(_root);
        }
        
        private void CreateSpecialFeatures()
        {
            var specialLine = new SpecialFeaturesClass();
            specialLine.CreateLine(_root);
        }
        
        private void CreateInspectorPanel()
        {
            var modelLine = new InspectorPanelClass();
            modelLine.CreateInspectorLine(_root);
        }
        
        // 色码转色号
        private static Color HexToColor(string hex)
        {
            // 移除开头的 #
            hex = hex.Replace("#", "");

            // 如果长度不是 6 或 8，抛出异常
            if (hex.Length != 6 && hex.Length != 8)
                throw new System.ArgumentException("Invalid hex color code");

            // 解析颜色分量
            var r = byte.Parse(hex.Substring(0, 2), System.Globalization.NumberStyles.HexNumber);
            var g = byte.Parse(hex.Substring(2, 2), System.Globalization.NumberStyles.HexNumber);
            var b = byte.Parse(hex.Substring(4, 2), System.Globalization.NumberStyles.HexNumber);
            var a = hex.Length == 8 ? byte.Parse(hex.Substring(6, 2), System.Globalization.NumberStyles.HexNumber) : (byte)255;

            return new Color(r / 255f, g / 255f, b / 255f, a / 255f);
        }
            
        private static void CheckAndSpawnPrefab()
        {
            // 获取当前场景
            var activeScene = SceneManager.GetActiveScene();
            var exists = activeScene.GetRootGameObjects().Any(obj => obj.GetComponent(ScriptComponent) != null);
            if (exists) return;
            // 加载预制体
            var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(PrefabPath);
            if (prefab == null)
            {
                Debug.LogError($"预制体未找到：{PrefabPath}");
                return;
            }
            // 创建实例并记录操作
            var instance = PrefabUtility.InstantiatePrefab(prefab, activeScene) as GameObject;
            Undo.RegisterCreatedObjectUndo(instance, "Create Manager Prefab");
            
            // 设置位置
            if (instance != null)
            {
                instance.transform.position = Vector3.zero;
                instance.name = "WorldMap";
            }
            // 标记场景需要保存
            if (!Application.isPlaying)
            {
                EditorSceneManager.MarkSceneDirty(activeScene);
            }
        }
    }
}

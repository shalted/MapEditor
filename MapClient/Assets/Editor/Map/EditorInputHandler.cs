#if UNITY_EDITOR
using Script;
using UnityEditor;
using UnityEngine;

namespace Editor.Map
{
    [InitializeOnLoad]
    public class EditorInputHandler
    {
        static EditorInputHandler()
        {
            SceneView.duringSceneGui += OnSceneGUI;
        }

        private static void OnSceneGUI(SceneView sceneView)
        {
            if (Event.current.type != EventType.MouseDown) return;
            var ray = HandleUtility.GUIPointToWorldRay(Event.current.mousePosition);
            if (!Physics.Raycast(ray, out var hit)) return;
            var controller = hit.collider.GetComponent<MapMain>();
            if (controller == null) return;
            // 模拟点击事件
            controller.UpdateMapEditor();
            Event.current.Use();
        }
    }
}
#endif
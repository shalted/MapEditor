using UnityEngine.UI;

namespace UnityEditor.UI
{
    [CustomEditor(typeof(Button), true)]
    [CanEditMultipleObjects]
    /// <summary>
    ///   Custom Editor for the Button Component.
    ///   Extend this class to write a custom editor for a component derived from Button.
    /// </summary>
    public class ButtonEditor : SelectableEditor
    {
        Image img;
        bool inited = false;

        SerializedProperty m_OnClickProperty;

        protected override void OnEnable()
        {
            base.OnEnable();
            m_OnClickProperty = serializedObject.FindProperty("m_OnClick");
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            EditorGUILayout.Space();

            serializedObject.Update();
            EditorGUILayout.PropertyField(m_OnClickProperty);
            serializedObject.ApplyModifiedProperties();
            if (img == null) {
                img = (target as Button).gameObject.GetComponent<Image>();
                if (img) {
                    img.raycastTarget = true;
                }
            }

            if (!inited) {
                (target as Button).transition = Selectable.Transition.None;
                Navigation nav = new Navigation();
                nav.mode = Navigation.Mode.None;
                (target as Button).navigation = nav;
                inited = true;
            }
        }
    }
}

using System.Linq;
using UnityEngine;
using UnityEditor.AnimatedValues;
using UnityEngine.UI;

namespace UnityEditor.UI
{
    /// <summary>
    /// Editor class used to edit UI Sprites.
    /// </summary>

    [CustomEditor(typeof(Image), true)]
    [CanEditMultipleObjects]
    /// <summary>
    ///   Custom Editor for the Image Component.
    ///   Extend this class to write a custom editor for a component derived from Image.
    /// </summary>
    public class ImageEditor : GraphicEditor
    {
        SerializedProperty m_FillMethod;
        SerializedProperty m_FillOrigin;
        SerializedProperty m_FillAmount;
        SerializedProperty m_FillClockwise;
        SerializedProperty m_Type;
        SerializedProperty m_FillCenter;
        SerializedProperty m_Sprite;
        SerializedProperty m_PreserveAspect;
        SerializedProperty m_UseSpriteMesh;
        SerializedProperty m_PixelsPerUnitMultiplier;
        SerializedProperty m_Rotation;
        SerializedProperty m_Grey;
        SerializedProperty m_SpriteKey;
        SerializedProperty m_MaterialKey;
        GUIContent m_SpriteContent;
        GUIContent m_SpriteTypeContent;
        GUIContent m_ClockwiseContent;
        AnimBool m_ShowSlicedOrTiled;
        AnimBool m_ShowSliced;
        AnimBool m_ShowTiled;
        AnimBool m_ShowFilled;
        AnimBool m_ShowType;
        AnimBool m_ShowSimpled;
		AnimBool m_ShowMirror;

        private class Styles
        {
            public static GUIContent text = EditorGUIUtility.TrTextContent("Fill Origin");
            public static GUIContent[] OriginHorizontalStyle =
            {
                EditorGUIUtility.TrTextContent("Left"),
                EditorGUIUtility.TrTextContent("Right")
            };

            public static GUIContent[] OriginVerticalStyle =
            {
                EditorGUIUtility.TrTextContent("Bottom"),
                EditorGUIUtility.TrTextContent("Top")
            };

            public static GUIContent[] Origin90Style =
            {
                EditorGUIUtility.TrTextContent("BottomLeft"),
                EditorGUIUtility.TrTextContent("TopLeft"),
                EditorGUIUtility.TrTextContent("TopRight"),
                EditorGUIUtility.TrTextContent("BottomRight")
            };

            public static GUIContent[] Origin180Style =
            {
                EditorGUIUtility.TrTextContent("Bottom"),
                EditorGUIUtility.TrTextContent("Left"),
                EditorGUIUtility.TrTextContent("Top"),
                EditorGUIUtility.TrTextContent("Right")
            };

            public static GUIContent[] Origin360Style =
            {
                EditorGUIUtility.TrTextContent("Bottom"),
                EditorGUIUtility.TrTextContent("Right"),
                EditorGUIUtility.TrTextContent("Top"),
                EditorGUIUtility.TrTextContent("Left")
            };
        }

        protected override void OnEnable()
        {
            base.OnEnable();

            m_SpriteContent = EditorGUIUtility.TrTextContent("Source Image");
            m_SpriteTypeContent     = EditorGUIUtility.TrTextContent("Image Type");
            m_ClockwiseContent      = EditorGUIUtility.TrTextContent("Clockwise");

            m_Sprite                = serializedObject.FindProperty("m_Sprite");
            m_Type                  = serializedObject.FindProperty("m_Type");
            m_FillCenter            = serializedObject.FindProperty("m_FillCenter");
            m_FillMethod            = serializedObject.FindProperty("m_FillMethod");
            m_FillOrigin            = serializedObject.FindProperty("m_FillOrigin");
            m_FillClockwise         = serializedObject.FindProperty("m_FillClockwise");
            m_FillAmount            = serializedObject.FindProperty("m_FillAmount");
            m_PreserveAspect        = serializedObject.FindProperty("m_PreserveAspect");
            m_UseSpriteMesh         = serializedObject.FindProperty("m_UseSpriteMesh");
            m_PixelsPerUnitMultiplier = serializedObject.FindProperty("m_PixelsPerUnitMultiplier");
            m_Rotation = serializedObject.FindProperty("m_Rotation");
            m_Grey = serializedObject.FindProperty("m_Grey");
            m_MaterialKey = serializedObject.FindProperty("materialKey");
            m_SpriteKey = serializedObject.FindProperty("spriteKey");

            m_ShowType = new AnimBool(m_Sprite.objectReferenceValue != null);
            m_ShowType.valueChanged.AddListener(Repaint);

            var typeEnum = (Image.Type)m_Type.enumValueIndex;

            m_ShowSlicedOrTiled = new AnimBool(!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Sliced);
            m_ShowSliced = new AnimBool(!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Sliced);
            m_ShowTiled = new AnimBool(!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Tiled);
            m_ShowFilled = new AnimBool(!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Filled);
            m_ShowSimpled = new AnimBool(!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Simple);
			m_ShowMirror = new AnimBool(!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Mirror);
            m_ShowSlicedOrTiled.valueChanged.AddListener(Repaint);
            m_ShowSliced.valueChanged.AddListener(Repaint);
            m_ShowTiled.valueChanged.AddListener(Repaint);
            m_ShowFilled.valueChanged.AddListener(Repaint);
            m_ShowSimpled.valueChanged.AddListener(Repaint);
			m_ShowMirror.valueChanged.AddListener(Repaint);


            SetShowNativeSize(true);
        }

        protected override void OnDisable()
        {
            m_ShowType.valueChanged.RemoveListener(Repaint);
            m_ShowSlicedOrTiled.valueChanged.RemoveListener(Repaint);
            m_ShowSliced.valueChanged.RemoveListener(Repaint);
            m_ShowTiled.valueChanged.RemoveListener(Repaint);
            m_ShowFilled.valueChanged.RemoveListener(Repaint);
            m_ShowSimpled.valueChanged.RemoveListener(Repaint);
			m_ShowMirror.valueChanged.RemoveListener(Repaint);
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            SpriteGUI();
            AppearanceControlsGUI();
            RaycastControlsGUI();
            MaskableControlsGUI();

            m_ShowType.target = m_Sprite.objectReferenceValue != null;
            if (EditorGUILayout.BeginFadeGroup(m_ShowType.faded))
                TypeGUI();
            EditorGUILayout.EndFadeGroup();

            if (m_SpriteKey != null) EditorGUILayout.PropertyField(m_SpriteKey);
            if (m_MaterialKey != null) EditorGUILayout.PropertyField(m_MaterialKey);
            if (m_Grey != null) EditorGUILayout.PropertyField(m_Grey);

            SetShowNativeSize(false);
            if (EditorGUILayout.BeginFadeGroup(m_ShowNativeSize.faded))
            {
                EditorGUI.indentLevel++;

                if ((Image.Type)m_Type.enumValueIndex == Image.Type.Simple)
                    EditorGUILayout.PropertyField(m_UseSpriteMesh);

                EditorGUILayout.PropertyField(m_PreserveAspect);
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndFadeGroup();
            NativeSizeButtonGUI();
            MirrorNativeSizeButtonGUI();
            EditorGUILayout.BeginHorizontal();
            Color customColor;
            EditorGUILayout.LabelField("ColorStr");
            m_customColor = EditorGUILayout.TextArea(m_customColor, new GUILayoutOption[] { GUILayout.Width(300f) });
            if (ParseColorFormat(m_customColor, out customColor))
            {
                if (m_Color != null)
                    m_Color.colorValue = customColor;
                m_customColor = "";
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Alpha");
            alpha = EditorGUILayout.FloatField(alpha, new GUILayoutOption[] { GUILayout.Width(300f) });
            if (alpha >= 0 && alpha <= 1)
            {
                Color t = m_Color.colorValue;
                t.a = alpha;
                m_Color.colorValue = t;
                alpha = -1;
            }
            EditorGUILayout.EndHorizontal();
            serializedObject.ApplyModifiedProperties();
        }

        void SetShowNativeSize(bool instant)
        {
            Image.Type type = (Image.Type)m_Type.enumValueIndex;
            bool showNativeSize = (type == Image.Type.Simple || type == Image.Type.Filled) && m_Sprite.objectReferenceValue != null;
            base.SetShowNativeSize(showNativeSize, instant);
        }

        /// <summary>
        /// Draw the atlas and Image selection fields.
        /// </summary>

        protected void SpriteGUI()
        {
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.PropertyField(m_Sprite, m_SpriteContent);
            if (EditorGUI.EndChangeCheck())
            {
                var newSprite = m_Sprite.objectReferenceValue as Sprite;
                if (newSprite)
                {
                    Image.Type oldType = (Image.Type)m_Type.enumValueIndex;
                    if (newSprite.border.SqrMagnitude() > 0)
                    {
                        m_Type.enumValueIndex = (int)Image.Type.Sliced;
                    }
                    else if (oldType == Image.Type.Sliced)
                    {
                        m_Type.enumValueIndex = (int)Image.Type.Simple;
                    }
                }
                (serializedObject.targetObject as Image).DisableSpriteOptimizations();
            }
        }

        /// <summary>
        /// Sprites's custom properties based on the type.
        /// </summary>

        protected void TypeGUI()
        {
            EditorGUILayout.PropertyField(m_Type, m_SpriteTypeContent);

            ++EditorGUI.indentLevel;
            {
                Image.Type typeEnum = (Image.Type)m_Type.enumValueIndex;

                bool showSlicedOrTiled = (!m_Type.hasMultipleDifferentValues && (typeEnum == Image.Type.Sliced || typeEnum == Image.Type.Tiled));
                if (showSlicedOrTiled && targets.Length > 1)
                    showSlicedOrTiled = targets.Select(obj => obj as Image).All(img => img.hasBorder);

                m_ShowSlicedOrTiled.target = showSlicedOrTiled;
                m_ShowSliced.target = (showSlicedOrTiled && !m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Sliced);
                m_ShowTiled.target = (showSlicedOrTiled && !m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Tiled);
                m_ShowFilled.target = (!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Filled);
                m_ShowSimpled.target = (!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Simple);
				m_ShowMirror.target = (!m_Type.hasMultipleDifferentValues && typeEnum == Image.Type.Mirror);

                Image image = target as Image;
                if (EditorGUILayout.BeginFadeGroup(m_ShowSimpled.faded))
                {
                    EditorGUILayout.PropertyField(m_Rotation);
                }
                EditorGUILayout.EndFadeGroup();
				if (EditorGUILayout.BeginFadeGroup(m_ShowMirror.faded))
                {
                    EditorGUILayout.PropertyField(m_Rotation);
                }
                EditorGUILayout.EndFadeGroup();
                if (EditorGUILayout.BeginFadeGroup(m_ShowSlicedOrTiled.faded))
                {
                    if (image.hasBorder)
                        EditorGUILayout.PropertyField(m_FillCenter);
                    EditorGUILayout.PropertyField(m_PixelsPerUnitMultiplier);
                }
                EditorGUILayout.EndFadeGroup();

                if (EditorGUILayout.BeginFadeGroup(m_ShowSliced.faded))
                {
                    if (image.sprite != null && !image.hasBorder)
                        EditorGUILayout.HelpBox("This Image doesn't have a border.", MessageType.Warning);
                }
                EditorGUILayout.EndFadeGroup();

                if (EditorGUILayout.BeginFadeGroup(m_ShowTiled.faded))
                {
                    if (image.sprite != null && !image.hasBorder && (image.sprite.texture.wrapMode != TextureWrapMode.Repeat || image.sprite.packed))
                        EditorGUILayout.HelpBox("It looks like you want to tile a sprite with no border. It would be more efficient to modify the Sprite properties, clear the Packing tag and set the Wrap mode to Repeat.", MessageType.Warning);
                }
                EditorGUILayout.EndFadeGroup();

                if (EditorGUILayout.BeginFadeGroup(m_ShowFilled.faded))
                {
                    EditorGUI.BeginChangeCheck();
                    EditorGUILayout.PropertyField(m_FillMethod);
                    if (EditorGUI.EndChangeCheck())
                    {
                        m_FillOrigin.intValue = 0;
                    }
                    var shapeRect = EditorGUILayout.GetControlRect(true);
                    switch ((Image.FillMethod)m_FillMethod.enumValueIndex)
                    {
                        case Image.FillMethod.Horizontal:
                            EditorGUI.Popup(shapeRect, m_FillOrigin, Styles.OriginHorizontalStyle, Styles.text);
                            break;
                        case Image.FillMethod.Vertical:
                            EditorGUI.Popup(shapeRect, m_FillOrigin, Styles.OriginVerticalStyle, Styles.text);
                            break;
                        case Image.FillMethod.Radial90:
                            EditorGUI.Popup(shapeRect, m_FillOrigin, Styles.Origin90Style, Styles.text);
                            break;
                        case Image.FillMethod.Radial180:
                            EditorGUI.Popup(shapeRect, m_FillOrigin, Styles.Origin180Style, Styles.text);
                            break;
                        case Image.FillMethod.Radial360:
                            EditorGUI.Popup(shapeRect, m_FillOrigin, Styles.Origin360Style, Styles.text);
                            break;
                    }
                    EditorGUILayout.PropertyField(m_FillAmount);
                    if ((Image.FillMethod)m_FillMethod.enumValueIndex > Image.FillMethod.Vertical)
                    {
                        EditorGUILayout.PropertyField(m_FillClockwise, m_ClockwiseContent);
                    }
                }
                EditorGUILayout.EndFadeGroup();
            }
            --EditorGUI.indentLevel;
        }

        /// <summary>
        /// All graphics have a preview.
        /// </summary>

        public override bool HasPreviewGUI() { return true; }

        /// <summary>
        /// Draw the Image preview.
        /// </summary>

        public override void OnPreviewGUI(Rect rect, GUIStyle background)
        {
            Image image = target as Image;
            if (image == null) return;

            Sprite sf = image.sprite;
            if (sf == null) return;

            SpriteDrawUtility.DrawSprite(sf, rect, image.canvasRenderer.GetColor());
        }

        /// <summary>
        /// A string containing the Image details to be used as a overlay on the component Preview.
        /// </summary>
        /// <returns>
        /// The Image details.
        /// </returns>

        public override string GetInfoString()
        {
            Image image = target as Image;
            Sprite sprite = image.sprite;

            int x = (sprite != null) ? Mathf.RoundToInt(sprite.rect.width) : 0;
            int y = (sprite != null) ? Mathf.RoundToInt(sprite.rect.height) : 0;

            return string.Format("Image Size: {0}x{1}", x, y);
        }

        protected void MirrorNativeSizeButtonGUI()
        {
            if (EditorGUILayout.BeginFadeGroup(m_ShowMirror.faded))
            {
                EditorGUILayout.BeginHorizontal();
                {
                    GUILayout.Space(EditorGUIUtility.labelWidth);
                    if (GUILayout.Button(EditorGUIUtility.TrTextContent("Set Native Size", "Sets the size to match the content."), EditorStyles.miniButton))
                    {
                        foreach (Graphic graphic in targets.Select(obj => obj as Graphic))
                        {
                            Undo.RecordObject(graphic.rectTransform, "Set Native Size");
                            MirrorNativeSize(graphic,m_Rotation.enumValueIndex);
                            EditorUtility.SetDirty(graphic);
                        }
                    }
                }
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndFadeGroup();
        }

        protected void MirrorNativeSize(Graphic graphic,int type)
        {
            Image img = (Image)graphic;
            img.SetNativeSize();
            Vector2 sizeDelta = img.rectTransform.sizeDelta;
            switch (type)
            {
                case 1:
                case 4:
                    img.rectTransform.sizeDelta = new Vector2(2*sizeDelta.x, sizeDelta.y);
                    break;
                case 2:
                case 5:
                    img.rectTransform.sizeDelta = new Vector2(sizeDelta.x, 2*sizeDelta.y);
                    break;
                case 3:
                    img.rectTransform.sizeDelta = new Vector2(2*sizeDelta.x, 2*sizeDelta.y);
                    break;
            }
            img.SetAllDirty();
        }
    }
}


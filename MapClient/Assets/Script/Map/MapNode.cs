using System.Text;
using UnityEngine;

namespace Script.Map
{
    public class MapNode : MonoBehaviour
    {
        private int row;
        private int column;
        private Vector3 v3;
        private StringBuilder str;
        private Camera mapCamera;

        private static readonly int MainTex = Shader.PropertyToID("_MainTex");

        // Start is called before the first frame update
        private void Start()
        {

        }
        
        public void Init(int curRow, int curColumn)
        {
            row = curRow;
            column = curColumn;
            v3 = Vector3.one;
            str = new StringBuilder(200);
            mapCamera = WorldMap.GetMapCamera();
        }
        
        public void UnInit()
        {
            transform.localPosition = Vector3.one * 20000;
        }
        
        public bool IsUseless(int curRow, int curColumn)
        {
            if (MapEnum.IsLoadAllMap) return false;
            if (row > curRow + 1 || row < curRow - 1) return true;
            return column > curColumn + 1 || column < curColumn - 1;
        }

        public void ChangeUISprite()
        {
            Debug.Log("changgeUISprite");
            str.Clear();
            str.Append(row).Append("_").Append(column);
            var texture = Resources.Load<Texture2D> (str.Insert(0, $"Map/{MapEnum.MapName}/map").ToString());
            if (texture == null)
            {
                return;
            }
            var props = new MaterialPropertyBlock();
            v3.x = texture.width / (float)MapEnum.Ppu;
            v3.y = texture.height / (float)MapEnum.Ppu;
            transform.localScale = v3;
            props.SetTexture(MainTex, texture);
            v3.x = (-(float)MapEnum.MapWidth / 2 + (float)MapEnum.MapNodeWidth * column + (float)texture.width / 2) / MapEnum.Ppu;
            v3.y = (-(float)MapEnum.MapHeight / 2 + (float)MapEnum.MapNodeHeight * row + (float)texture.height / 2) / MapEnum.Ppu;
            transform.localPosition = v3;
            GetComponent<MeshRenderer>().SetPropertyBlock(props);
            gameObject.SetActive(true);
        }
    }
}

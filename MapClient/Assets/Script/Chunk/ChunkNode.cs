using Script.Map;
using UnityEngine;

namespace Script.Chunk
{
    public class ChunkNode : MonoBehaviour
    {
        private int _row;
        private int _col;
        private Vector3 _v3 = Vector3.zero;
        private string _curLayer;
        private static readonly int Color1 = Shader.PropertyToID("_Color");
        private static readonly int Alpha = Shader.PropertyToID("_Alpha");
        private static readonly int Mode = Shader.PropertyToID("_Mode");

        public void Init(int row, int col)
        {
            _row = row;
            _col = col;
            _v3.x = (-(float)MapEnum.MapWidth / 2 + (float)MapEnum.CellSize * _col + (float)MapEnum.CellSize / 2) / MapEnum.Ppu;
            _v3.y = (-(float)MapEnum.MapHeight / 2 + (float)MapEnum.CellSize * _row + (float)MapEnum.CellSize/ 2) / MapEnum.Ppu;
            transform.localPosition = _v3;
            gameObject.SetActive(true);
            _curLayer = MapEnum.ChunkMode;
            transform.localScale = Vector3.one * MapEnum.CellSize / (float)MapEnum.Ppu;
            GetComponent<MeshRenderer>().material = Resources.Load<Material>($"Material/{MapEnum.ChunkMaterialName}");
            transform.name = $"{_row} {_col}";
        }
        
        public Vector3 GetSavePosition()
        {
            _v3.x = Mathf.Floor(transform.localPosition.x * 100);
            _v3.y = Mathf.Floor(transform.localPosition.y * 100);
            return _v3;
        }
        
        public string GetSaveLayer()
        {
            return _curLayer;
        }
        
        public void DeleteMe()
        {
            Destroy(gameObject);
        }
    }
}
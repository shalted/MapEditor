using System.Text;
using Script.Map;
using TMPro;
using UnityEngine;

namespace Script.Model
{
    public class AreaNode : MonoBehaviour
    {
        private int _row;
        private int _col;
        private int _resourcesId;
        private string _areaName;
        private TextMeshProUGUI name;
        private Vector3 _v3 = Vector3.zero;
        
        public void Start()
        {
            name = transform.Find("Canvas/name").GetComponent<TextMeshProUGUI>();
            name.text = _areaName;
        }

        public void Init(int row, int col)
        {
            _row = row;
            _col = col;
            _v3.x = (-(float)MapEnum.MapWidth / 2 + (float)MapEnum.CellSize * _col + (float)MapEnum.CellSize / 2) / MapEnum.Ppu;
            _v3.y = (-(float)MapEnum.MapHeight / 2 + (float)MapEnum.CellSize * _row + (float)MapEnum.CellSize/ 2) / MapEnum.Ppu;
            transform.localPosition = _v3;
            gameObject.SetActive(true);
            _areaName = MapEnum.AreaName;
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
        
        public string GetAreaName()
        {
            return _areaName;
        }

        public void DeleteMe()
        {
            Destroy(gameObject);
        }
    }
}
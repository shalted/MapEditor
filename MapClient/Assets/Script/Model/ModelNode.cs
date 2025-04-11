using System.Text;
using Script.Map;
using UnityEngine;

namespace Script.Model
{
    public class ModelNode : MonoBehaviour
    {
        private int _row;
        private int _col;
        private int _resourcesId;
        private string _modelName;
        private Vector3 _v3 = Vector3.zero;

        public void Init(int row, int col, Vector3 worldPos)
        {
            _row = row;
            _col = col;
            //Debug.Log($"Init ModelNode {_row} {_col}");
            CreatePrefab();
            var config = WorldMap.GetModelConfigById(MapEnum.ResourcesId);
            _resourcesId = MapEnum.ResourcesId;
            if (config.IsLogic == "否")
            {
                var list = config.Position.Split(',');
                Debug.Log($"Init ModelNode {_row} {_col} {_modelName} {list[0]} {list[1]}");
                _v3.x = (-(float)MapEnum.MapWidth / 2 + (float)MapEnum.CellSize * _col + (float)MapEnum.CellSize * int.Parse(list[0]) / 2) / MapEnum.Ppu;
                _v3.y = (-(float)MapEnum.MapHeight / 2 + (float)MapEnum.CellSize * _row + (float)MapEnum.CellSize * int.Parse(list[1]) / 2) / MapEnum.Ppu;
                transform.localPosition = _v3;
            }
            else
            {
                //Debug.Log($"Init ModelNode {_row} {_col} {_modelName}");
                SetPosition(worldPos);
            }
            SetScale();
            gameObject.SetActive(true);
        }
        
        private void CreatePrefab()
        {
            var config = WorldMap.GetModelConfigById(MapEnum.ResourcesId);
            var enemyPrefab = Resources.Load<GameObject>($"Prefabs/{config.Model}");
            _modelName = config.Name;
            if (enemyPrefab != null)
            {
                // 实例化预制体到场景
                Instantiate(enemyPrefab, transform);
            }
        }
        
        private void SetPosition(Vector3 worldPos)
        {
            transform.localPosition = worldPos;
        }
        
        private void SetScale()
        {
            transform.localScale = Vector3.one * MapEnum.ModelSize;
        }
        
        public Vector3 GetSavePosition()
        {
            _v3.x = Mathf.Floor(transform.localPosition.x * 100);
            _v3.y = Mathf.Floor(transform.localPosition.y * 100);
            return _v3;
        }
        
        public string GetModelName()
        {
            return _modelName;
        }
        
        public int GetResId()
        {
            return _resourcesId;
        }
        
        public void DeleteMe()
        {
            Destroy(gameObject);
        }
    }
}
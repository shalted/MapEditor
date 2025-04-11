using Script.Map;
using UnityEngine;
using UnityEngine.EventSystems;
// ReSharper disable PossibleLossOfFraction

namespace Script
{
    public delegate void NotifyUpdateMap(int row, int column);
    public class MapMain : MonoBehaviour
    {
        public event NotifyUpdateMap OnUpdateMap;
        private Vector2 movePosition; 
        private float maxWidth;
        private float minWidth;
        private float maxHeight;
        private float minHeight;
        private int maxWidthCell;
        private int maxHeightCell;
        private float cellWidth;
        private float cellHeight;
        
        private int curRow;
        private int curColumn;
        private Vector3 v3;
        private Camera mapCamera;
        private void Start()
        {
            FormatPanelData();
        }
        
        public void Init(Camera cam)
        {
            mapCamera = cam;
            curRow = -1;
            curColumn = -1;
        }
        
        public void FormatPanelData()
        {
            maxWidth = ((float)MapEnum.MapWidth / 2 - (float)MapEnum.ScreenWidth / 2) / (float)MapEnum.Ppu;
            minWidth = (-(float)MapEnum.MapWidth / 2 + (float)MapEnum.ScreenWidth / 2) / (float)MapEnum.Ppu;
            maxHeight = ((float)MapEnum.MapHeight / 2 - (float)MapEnum.ScreenHeight / 2) / (float)MapEnum.Ppu;
            minHeight = (-(float)MapEnum.MapHeight / 2 + (float)MapEnum.ScreenHeight / 2) / (float)MapEnum.Ppu;
            maxWidthCell = (int)Mathf.Ceil((int)MapEnum.MapWidth / (int)MapEnum.MapNodeWidth);
            maxHeightCell = (int)Mathf.Ceil((int)MapEnum.MapHeight / (int)MapEnum.MapNodeHeight);
            cellWidth = (int)MapEnum.MapNodeWidth / (float)MapEnum.Ppu;
            cellHeight = (int)MapEnum.MapNodeHeight / (float)MapEnum.Ppu;
            v3 = new Vector3();
            if (!mapCamera) return;
            v3.x = 0;
            v3.y = 0;
            v3.z = -100;
            mapCamera.transform.localPosition = v3;
        }

        public void OnDrag(PointerEventData eventData)
        {
            v3 = eventData.delta;
            v3.x /= (float)MapEnum.Ppu;
            v3.y /= (float)MapEnum.Ppu;
            v3 = mapCamera.transform.localPosition - v3;
            v3.x = Mathf.Clamp(v3.x, minWidth, maxWidth);
            v3.y = Mathf.Clamp(v3.y, minHeight, maxHeight);
            mapCamera.transform.localPosition = v3;
            var column = (int)(Mathf.Floor((int)MapEnum.MapWidth / (2 * (int)MapEnum.Ppu) + mapCamera.transform.localPosition.x) / cellWidth);
            var row = (int)(Mathf.Floor((int)MapEnum.MapHeight / (2 * (int)MapEnum.Ppu) - mapCamera.transform.localPosition.y) / cellHeight);
            column = Mathf.Clamp(column, 0, maxWidthCell);
            row = Mathf.Clamp(row, 0, maxHeightCell);
            OnMapUpdate(row, column);
        }
        
        public void UpdateMap()
        {
            var column = (int)Mathf.Floor((Mathf.Floor((float)MapEnum.MapWidth / 2) - mapCamera.transform.localPosition.x) / (float)MapEnum.MapNodeWidth);
            var row = (int)Mathf.Floor((Mathf.Floor((float)MapEnum.MapHeight / 2) + mapCamera.transform.localPosition.y) / (float)MapEnum.MapNodeHeight);
            OnMapUpdate(row, column, true);
        }
        
        public void UpdateMapEditor()
        {
            Debug.Log("UpdateMapEditor");
        }
        
        private void OnMapUpdate(int row, int column, bool isRefresh = false)
        {
            if (curRow == row && curColumn == column)
            {
                if (!isRefresh)
                {
                    return;
                }
            }
            curRow = row;
            curColumn = column;
            OnUpdateMap?.Invoke(row, column);
        }
    }
}
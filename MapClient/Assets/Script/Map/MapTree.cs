using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Script.Map
{
    [SuppressMessage("ReSharper", "PossibleLossOfFraction")]
    public class MapTree : MonoBehaviour
    {
        private Dictionary<string, MapNode> mapNodeList;

        private Transform mapNodeTrs;
        private Vector3 v3;

        // Start is called before the first frame update

        private void Start()
        {

        }
        
        public void Init()
        {
            mapNodeList = new Dictionary<string, MapNode>();
            v3 = new Vector3();
            mapNodeTrs = transform.Find("MapNode");
        }
        
        public void UnInit()
        {
            foreach (var value in mapNodeList)
            {
                value.Value.UnInit();
            }
        }
        
        public void UpdateMap(int row, int column)
        {
            var str = new StringBuilder(200);
            FormatRowAndColumnData(out var rowStart, out var rowEnd, out var columnStart, out var columnEnd, row, column);
            for (var i = columnStart; i <= columnEnd; i++)
            {
                for (var j = rowStart; j <= rowEnd; j++)
                {
                    str.Append(i).Append("_").Append(j);
                    MapNode tempNode;
                    if (mapNodeList.ContainsKey(str.ToString()))
                    {
                        tempNode = mapNodeList[str.ToString()];
                    }
                    else
                    {
                        var tempMapNode = GetCurTrans(row, column,  str);
                        tempNode = tempMapNode.GetComponent<MapNode>();
                        tempNode.Init(j, i);
                        mapNodeList.Add(str.ToString(), tempNode);
                    }
                    tempNode.ChangeUISprite();
                    str.Clear();
                }
            }
        }
        
        private void FormatRowAndColumnData(out int rowStart, out int rowEnd, out int columnStart, out int columnEnd, int row, int column)
        {
            if (MapEnum.IsLoadAllMap)
            {
                rowStart = 0;
                rowEnd = (int)Mathf.Ceil(MapEnum.MapHeight / MapEnum.MapNodeHeight);
                columnStart = 0;
                columnEnd = (int)Mathf.Ceil(MapEnum.MapWidth / MapEnum.MapNodeWidth);
            }
            else
            {
                rowStart = row - 1;
                rowEnd = row + 1;
                columnStart = column - 1;
                columnEnd = column + 1;
            }
        }
        
        private Transform GetCurTrans(int row, int column, StringBuilder str)
        {
            Transform tempMapNode = new RectTransform();
            foreach (var mapNode in mapNodeList.Where(mapNode => mapNode.Value.IsUseless(row, column)))
            {
                tempMapNode = mapNode.Value.transform;
                mapNodeList.Remove(mapNode.Key);
                break;
            }
            if (tempMapNode == null)
            {
                tempMapNode = Instantiate(mapNodeTrs, transform);
                tempMapNode.name = str.ToString();
            }

            return tempMapNode;
        }
    }
}

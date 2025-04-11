using System.Collections.Generic;

namespace Script.Map
{
    public static class ModelMapData
    {

        private static Dictionary<string, List<ModelData>> _modelNodeDict;

        public struct ModelData
        {
            public int CoordinateX;
            public int CoordinateY;
            public int PosX;
            public int PosY;
            public string Layer;
            public int ResourcesId;
            public ModelData(int coordinateX, int coordinateY, int posX, int posY, string layer, int resourcesId)
            {
                CoordinateX = coordinateX;
                CoordinateY = coordinateY;
                PosX = posX;
                PosY = posY;
                Layer = layer;
                ResourcesId = resourcesId;
            }
        }
        public static void InitModelData()
        {
            _modelNodeDict = new Dictionary<string, List<ModelData>>();

            ModelData modelData;
            _modelNodeDict.Add("TreePoint", new List<ModelData>());
        }


        public static Dictionary<string, List<ModelData>> GetModelDirection()
        {
            return _modelNodeDict;
        }
    }
}
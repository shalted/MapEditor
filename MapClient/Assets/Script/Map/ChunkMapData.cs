using System.Collections.Generic;

namespace Script.Map
{
    public static class ChunkMapData
    {

        private static Dictionary<string, List<ChunkData>> _chunkNodeDict;

        public struct ChunkData
        {
            public int CoordinateX;
            public int CoordinateY;
            public int PosX;
            public int PosY;
            public string Layer;
            public ChunkData(int coordinateX, int coordinateY, int posX, int posY, string layer)
            {
                CoordinateX = coordinateX;
                CoordinateY = coordinateY;
                PosX = posX;
                PosY = posY;
                Layer = layer;
            }
        }
        public static void InitChunkData()
        {
            _chunkNodeDict = new Dictionary<string, List<ChunkData>>();

            ChunkData chunkData;
            _chunkNodeDict.Add("NonBuildableLayer", new List<ChunkData>());
            _chunkNodeDict.Add("ResourceLayer", new List<ChunkData>());
        }


        public static Dictionary<string, List<ChunkData>> GetChunkDirection()
        {
            return _chunkNodeDict;
        }
    }
}
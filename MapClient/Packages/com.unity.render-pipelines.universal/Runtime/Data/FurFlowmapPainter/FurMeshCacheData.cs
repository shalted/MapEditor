using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if  UNITY_EDITOR
using UnityEditor;
#endif
using System.IO;

#if  UNITY_EDITOR
[System.Serializable]
[RequireComponent(typeof(Renderer))]
public class FurMeshCacheData : MonoBehaviour
{
    //功能缓存数据
    [SerializeField]
    Mesh _sharedMesh;

    [SerializeField]
    Mesh _meshColliderCacheMesh;
    
    [SerializeField]
    Texture2D[] _flowMapGroup;
    
    [SerializeField]
    List<Material> _flowMapMaterialList;
    
    [SerializeField]
    List<int> _flowMapMaterialIndexList;
    
    //逻辑缓存数据
    [SerializeField]
    private string _flowMapPath = "";
    
    [SerializeField]
    int _selFlowMap = 0;

    [SerializeField]
    [HideInInspector]
    bool _isSelect = false;
    
    [SerializeField]
    [HideInInspector]
    bool _openReadWrite = false;
    
    [SerializeField]
    [HideInInspector]
    bool _hasMeshCollider = false;
    
    public bool IsSelect => _isSelect;
    
    int furFlowMap_ID = Shader.PropertyToID("_FurFlowMap");
    int baseMap_ID = Shader.PropertyToID("_BaseMap");

    public void Init()
    {//初始化缓存数据
     //由FurFlowmapEditorWindow.InitFurMeshCatchDataBySelect()调用
        if (_sharedMesh == null)
        {
            //缓存网格
            var meshFilter = transform.GetComponent<MeshFilter>();
            if (meshFilter != null)
            {
                _sharedMesh = meshFilter.sharedMesh;
            }
            else
            {
                var skinnedMeshRenderer = transform.GetComponent<SkinnedMeshRenderer>();
                _sharedMesh = skinnedMeshRenderer.sharedMesh;
            }
            
            //设置MeshCollider
            var meshCollider = gameObject.GetComponent<MeshCollider>();
            if (meshCollider != null)
            {
                _hasMeshCollider = true;
                _meshColliderCacheMesh = meshCollider.sharedMesh;
                meshCollider.sharedMesh = _sharedMesh;
            }
            else
            {
                gameObject.AddComponent<MeshCollider>();
                gameObject.GetComponent<MeshCollider>().sharedMesh = _sharedMesh;
            }

            _flowMapMaterialList = new List<Material>();
            _flowMapMaterialIndexList = new List<int>();


            //缓存材质和FlowMap
            var goMaterials = transform.GetComponent<Renderer>().sharedMaterials;
            List<Texture2D> flowMapList = new List<Texture2D>();
            for (int i = 0; i < goMaterials.Length; i++)
            // foreach (var currentMaterial in goMaterials)
            {
                var currentMaterial = goMaterials[i];
                
                if (currentMaterial.HasProperty(furFlowMap_ID))
                {
                    Texture2D furFlowMap = (Texture2D)currentMaterial.GetTexture(furFlowMap_ID);
                    if (furFlowMap != null)
                    {
                        _flowMapPath = AssetDatabase.GetAssetPath(furFlowMap);
                    
                        _flowMapMaterialList.Add(currentMaterial);
                        _flowMapMaterialIndexList.Add(i);
                        flowMapList.Add(furFlowMap);
                        continue;
                    }
                    else
                    {
                        _flowMapMaterialList.Add(currentMaterial);
                        _flowMapMaterialIndexList.Add(i);
                        flowMapList.Add(null);
                    }
                
                    Texture2D baseMap = (Texture2D)currentMaterial.GetTexture(baseMap_ID);
                    if (baseMap != null)
                    {
                        _flowMapPath = AssetDatabase.GetAssetPath(baseMap);
                    }
                }
            }
            _flowMapGroup = flowMapList.ToArray();
            // FlowMapTex = _flowMapGroup[selFlowMap];
        }
    }
    
    public void SetSelect(bool isSelect)
    {
        _isSelect = isSelect;
    }
    
    public bool GetOpenReadWrite()
    {
        return _openReadWrite;
    }

    public string GetFlowMapPath()
    {
        return _flowMapPath;
    }
    
    public void SetFlowMapPath(string newFlowMapPath)
    {
        _flowMapPath = newFlowMapPath;
    }

    public Texture2D[] GetFlowMapGroup()
    {
        return _flowMapGroup;
    }
    
    public float GetSharedMeshBoundsSize()
    {
        //_sharedMesh.HasVertexAttribute()
        // _sharedMesh.bounds.Contains()
        
        return _sharedMesh.bounds.size.x;
    }
    
    public List<Material> GetFlowMapMaterialList()
    {
        return _flowMapMaterialList;
    }
    
    public List<int> GetFlowMapMaterialIndexList()
    {
        return _flowMapMaterialIndexList;
    }

    public int GetSubMeshCount()
    {
        return _sharedMesh.subMeshCount;
    }

    public bool OperationPointIsCurrentMaterial(Vector3 operationPoint, int subMeshIndex, int triangleIndex)
    {//计算当前操作点所属的SubMesh所有
        if (GetEncapsulatedBoundsInSpace(_sharedMesh.GetSubMesh(subMeshIndex).bounds, transform.localToWorldMatrix).Contains(operationPoint))
        {//包围盒粗判断
            int[] triangles = _sharedMesh.triangles;
            int i0 = triangles[triangleIndex * 3];
            int i1 = triangles[triangleIndex * 3 + 1];
            int i2 = triangles[triangleIndex * 3 + 2];

            var indices= _sharedMesh.GetIndices(subMeshIndex);
            int vertexCount = indices.Length;
            for(int j = 0; j < vertexCount; j += 3)
            {//顶点索引详细判断
                int j0 = indices[j];
                int j1 = indices[j+1];
                int j2 = indices[j+2];
                //如果子网格的索引与命中三角形匹配，则表示是命中的子网格
                if(i0 == j0 && i1 == j1 && i2 == j2)
                {
                    return true;
                }
            }
        }
        return false;
        // return _sharedMesh.GetSubMesh(index).bounds.Contains(operationPoint);
    }

    public Bounds GetSubMeshBoundsWs(int index)
    {
        return GetEncapsulatedBoundsInSpace(_sharedMesh.GetSubMesh(index).bounds, transform.localToWorldMatrix);
    }

    public Texture2D GetFlowMap(int index)
    {
        return _flowMapGroup[index];
    }

    public void Clear()
    {//清除缓存数据
        //恢复FlowMap的贴图导入设置
        if (_openReadWrite)
        {
            SetFlowMapSetting(false);
        }

        //恢复MeshCollider设置
        if (_hasMeshCollider)
        {
            gameObject.GetComponent<MeshCollider>().sharedMesh = _meshColliderCacheMesh;
        }
        else
        {
            if (gameObject.GetComponent<MeshCollider>() != null)
            {
                DestroyImmediate(gameObject.GetComponent<MeshCollider>());
            }
        }

        _sharedMesh = null;
        _meshColliderCacheMesh = null;
        _flowMapGroup = null;
        _flowMapMaterialList.Clear();
        _flowMapMaterialIndexList.Clear();
    }

    public void ReGetFlowMap()
    {//重新获取FlowMap
        _flowMapGroup = null;
        _flowMapMaterialList.Clear();
        _flowMapMaterialIndexList.Clear();

        //缓存材质和FlowMap
        var goMaterials = transform.GetComponent<Renderer>().sharedMaterials;
        List<Texture2D> flowMapList = new List<Texture2D>();

        for (int i = 0; i < goMaterials.Length; i++)
        // foreach (var currentMaterial in goMaterials)
        {
            var currentMaterial = goMaterials[i];
            
            if (currentMaterial.HasProperty(furFlowMap_ID))
            {
                Texture2D furFlowMap = (Texture2D)currentMaterial.GetTexture(furFlowMap_ID);
                if (furFlowMap != null)
                {
                    _flowMapPath = AssetDatabase.GetAssetPath(furFlowMap);
                    
                    _flowMapMaterialList.Add(currentMaterial);
                    _flowMapMaterialIndexList.Add(i);
                    flowMapList.Add(furFlowMap);
                    continue;
                }
                else
                {
                    _flowMapMaterialList.Add(currentMaterial);
                    _flowMapMaterialIndexList.Add(i);
                    flowMapList.Add(null);
                }
                
                Texture2D baseMap = (Texture2D)currentMaterial.GetTexture(baseMap_ID);
                if (baseMap != null)
                {
                    _flowMapPath = AssetDatabase.GetAssetPath(baseMap);
                }
            }
        }
        _flowMapGroup = flowMapList.ToArray();
    }
    
    public void SetFlowMapSetting(bool openReadWrite)
    {//更改FlowMap导入设置
        if (openReadWrite)
        {
            foreach (var currentFlowMap in _flowMapGroup)
            {
                if (currentFlowMap == null)
                {
                    continue;
                }
                var dataPath = AssetDatabase.GetAssetPath(currentFlowMap);
                TextureImporter ti = (TextureImporter)AssetImporter.GetAtPath(dataPath);
        
                ti.isReadable = openReadWrite;//使用笔刷前先把FlowMap的读写打开
                ti.sRGBTexture = false;
            
                TextureImporterPlatformSettings settingPC = new TextureImporterPlatformSettings();
                settingPC.name = BuildTarget.StandaloneWindows.ToString ();
                settingPC.maxTextureSize = 1024;
                settingPC.format = TextureImporterFormat.RGBA32;
                settingPC.overridden = true;
                ti.SetPlatformTextureSettings(settingPC);
            
                ti.SaveAndReimport();
            }
        }
        else
        {
            foreach (var currentFlowMap in _flowMapGroup)
            {
                if (currentFlowMap == null)
                {
                    continue;
                }
                var dataPath = AssetDatabase.GetAssetPath(currentFlowMap);
                TextureImporter ti = (TextureImporter)AssetImporter.GetAtPath(dataPath);
        
                ti.isReadable = openReadWrite;//使用完后把FlowMap的读写关闭

                ti.SaveAndReimport();
            }
        }
        
        _openReadWrite = openReadWrite;
    }
    
    public static Bounds GetEncapsulatedBoundsInSpace(Bounds bounds, Matrix4x4 transformMatrix)
    {//将包围盒转换到指定空间下
        Vector3[] globalTempCubeCorners = new Vector3[8];
        
        GetCornersFromBounds(bounds, globalTempCubeCorners);
        return GetEncapsulatedBoundsInSpace(globalTempCubeCorners, transformMatrix);
    }
    
    static void GetCornersFromBounds(Bounds bounds, Vector3[] outCorners)
    {//计算包围盒顶点
        if (outCorners.Length != 8)
        {
            return;
        }

        Vector3 max = bounds.max, min = bounds.min;
/*
        outCorners[0] = max;
        outCorners[1] = min;
        outCorners[2] = new Vector3(min.x, max.y, min.z);
        outCorners[3] = new Vector3(min.x, max.y, max.z);
        outCorners[4] = new Vector3(max.x, max.y, min.z);
        outCorners[5] = new Vector3(min.x, min.y, min.z);//min重复了
        outCorners[6] = new Vector3(min.x, min.y, max.z);
        outCorners[7] = new Vector3(max.x, min.y, min.z);*/

        //↓
        
        outCorners[0] = min;
        outCorners[1] = new Vector3(max.x, min.y, min.z);
        outCorners[2] = new Vector3(max.x, min.y, max.z);//min重复了，漏了这个
        outCorners[3] = new Vector3(min.x, min.y, max.z);
        outCorners[4] = new Vector3(min.x, max.y, min.z);
        outCorners[5] = new Vector3(max.x, max.y, min.z);
        outCorners[6] = max;
        outCorners[7] = new Vector3(min.x, max.y, max.z);
        
    }
    
    static Bounds GetEncapsulatedBoundsInSpace(Vector3[] corners, Matrix4x4 transformMatrix)
    {//将包围盒顶点进行空间转换，输出对应空间下的包围盒
        if (corners.Length != 8)
        {
            throw new System.Exception("GetEncapsulatedBoundsInSpace：输入的Bounds少于8个顶点数据");
        }
        
        Vector3 max_ = transformMatrix.MultiplyPoint3x4(corners[0]);
        Vector3 min_ = transformMatrix.MultiplyPoint3x4(corners[1]);
        Vector3 up1_ = transformMatrix.MultiplyPoint3x4(corners[2]);
        Vector3 up2_ = transformMatrix.MultiplyPoint3x4(corners[3]);
        Vector3 up3_ = transformMatrix.MultiplyPoint3x4(corners[4]);
        Vector3 lo1_ = transformMatrix.MultiplyPoint3x4(corners[5]);
        Vector3 lo2_ = transformMatrix.MultiplyPoint3x4(corners[6]);
        Vector3 lo3_ = transformMatrix.MultiplyPoint3x4(corners[7]);
        

        /*
        Bounds newBounds = new Bounds(max_, Vector3.zero);
        newBounds.Encapsulate(min_);
        newBounds.Encapsulate(up1_);
        newBounds.Encapsulate(up2_);
        newBounds.Encapsulate(up3_); // bounds.encapsulate has poor performance
        newBounds.Encapsulate(lo1_);
        newBounds.Encapsulate(lo2_);
        newBounds.Encapsulate(lo3_);
        */

        Vector3 bMin = max_;
        Vector3 bMax = max_;
        MakeMin(ref bMin, min_);
        MakeMax(ref bMax, max_);
        MakeMin(ref bMin, up1_);
        MakeMax(ref bMax, up1_);
        MakeMin(ref bMin, up2_);
        MakeMax(ref bMax, up2_);
        MakeMin(ref bMin, up3_);
        MakeMax(ref bMax, up3_);
        MakeMin(ref bMin, lo1_);
        MakeMax(ref bMax, lo1_);
        MakeMin(ref bMin, lo2_);
        MakeMax(ref bMax, lo2_);
        MakeMin(ref bMin, lo3_);
        MakeMax(ref bMax, lo3_);
        return new Bounds((bMin + bMax) / 2, bMax - bMin);
    }
    
    static void MakeMin(ref Vector3 src, in Vector3 vec)
    {
        src.x = Mathf.Min(src.x, vec.x);
        src.y = Mathf.Min(src.y, vec.y);
        src.z = Mathf.Min(src.z, vec.z);
    }

    static void MakeMax(ref Vector3 src, in Vector3 vec)
    {
        src.x = Mathf.Max(src.x, vec.x);
        src.y = Mathf.Max(src.y, vec.y);
        src.z = Mathf.Max(src.z, vec.z);
    }
}
#endif
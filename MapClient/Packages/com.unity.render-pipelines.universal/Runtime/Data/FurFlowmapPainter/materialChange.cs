using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class materialChange : MonoBehaviour
{
    public List<Material> matlist;

    public Material thismat;
    
    private float timer = 0f; // 计时器
    public float splittime = 1f; // 更新间隔
    private int a = 0; // 需要更新的变量
    [Space(20)]
    public List<int> id = new List<int>();
    public List<Material> addmat;

    private bool ifskin;
    
    void Start()
    {
        if (this.GetComponent<SkinnedMeshRenderer>() == null)
            ifskin = false;
        else
            ifskin = true;

        if(ifskin)
            thismat = this.GetComponent<SkinnedMeshRenderer>().sharedMaterial;
        else
            thismat = this.GetComponent<MeshRenderer>().sharedMaterial;
        
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        int matlistcount = this.matlist.Count;
        
        // 每帧更新计时器
        timer += Time.deltaTime;

        // 如果计时器超过了指定的更新间隔
        if (timer >= splittime)
        {
            //change mat
            a++;
            if ((a+1) > matlistcount)
            {
                a = 0;
            }
            if (matlist[a] != null)
            {
                List<Material> temp = new List<Material>();
                //存在可添加的队列id
                if (id.Contains(a))
                {
                    
                    temp.Add(matlist[a]);
                    temp.Add(addmat[id.IndexOf(a)]);
                    if(ifskin)
                        this.GetComponent<SkinnedMeshRenderer>().SetSharedMaterials(temp);
                    else
                        this.GetComponent<MeshRenderer>().SetSharedMaterials(temp);
                    
                }
                else
                {
                    temp.Add(matlist[a]);
                    if(ifskin)
                        this.GetComponent<SkinnedMeshRenderer>().SetSharedMaterials(temp);
                    else
                        this.GetComponent<MeshRenderer>().SetSharedMaterials(temp);
                    
                }
            }
            // 重置计时器
            timer = 0f;
        }
    }
}


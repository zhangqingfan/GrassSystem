using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectMove : MonoBehaviour
{
    // Update is called once per frame
   
    void Update()
    {

            Shader.SetGlobalVector("_PositionMoving", transform.position);
            Shader.SetGlobalFloat("_Radius", 0.5f);
            Debug.Log(transform.position);

    }
}

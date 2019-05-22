using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotationYoYo : MonoBehaviour
{
    public float xAngle;
    public float yAngle;
    public float zAngle;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(xAngle, yAngle, zAngle, Space.World);
    }

}

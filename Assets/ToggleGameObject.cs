using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ToggleGameObject : MonoBehaviour
{
    public GameObject myGameObject;

    private bool myIsActive;

    public void OnClick()
    {
        myIsActive = !myIsActive;
        myGameObject.SetActive(myIsActive);
    }
}

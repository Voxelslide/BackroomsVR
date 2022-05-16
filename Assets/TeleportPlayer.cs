using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TeleportPlayer : MonoBehaviour
{
	public void TeleportDown()
	{
		gameObject.transform.parent.transform.parent.transform.position = new Vector3(transform.position.x, transform.position.y - 8.268f, transform.position.z);
		
	}
}

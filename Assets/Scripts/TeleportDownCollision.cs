using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TeleportDownCollision : MonoBehaviour
{
	//We need to teleport the player down 8.268 units when they collide with this box
	void OnTriggerEnter(Collider collision)
	{
		if (collision.transform.CompareTag("Player"))
		{
			collision.transform.GetComponent<TeleportPlayer>().TeleportDown();
		}
	}
}

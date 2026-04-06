using UnityEngine;

public enum CardType { Unit, Spell, Building }

// Create card assets via: right-click in Project > Create > Game/Card
[CreateAssetMenu(fileName = "NewCard", menuName = "Game/Card")]
public class CardData : ScriptableObject
{
    [Header("Identity")]
    public string cardName;
    public Sprite cardSprite;
    public CardType cardType;

    [Header("Cost")]
    [Range(1, 9)]
    public int elixirCost = 3;

    [Header("Unit/Building Prefab")]
    public GameObject prefab;          // spawned on the arena when played

    [Header("Spell Settings")]
    public float spellRadius = 2f;     // used only when cardType == Spell
    public int spellDamage = 400;
}

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

// Manages the player's hand (4 cards) and card spawning.
// Attach to a UI Canvas object.
public class CardManager : MonoBehaviour
{
    [Header("Deck (8 cards)")]
    public List<CardData> deck = new List<CardData>();   // assign in Inspector

    [Header("Hand UI (4 slots)")]
    public Image[] cardImages = new Image[4];
    public TextMeshProUGUI[] costTexts = new TextMeshProUGUI[4];

    [Header("Next Card Preview")]
    public Image nextCardImage;

    [Header("Arena Spawn")]
    public Camera arenaCamera;
    public LayerMask arenaLayerMask;

    private List<CardData> hand = new List<CardData>();
    private Queue<CardData> drawPile = new Queue<CardData>();
    private int selectedCardIndex = -1;
    public int ownerPlayerID = 1;

    void Start()
    {
        InitializeDeck();
        DrawInitialHand();
    }

    void InitializeDeck()
    {
        List<CardData> shuffled = new List<CardData>(deck);
        for (int i = shuffled.Count - 1; i > 0; i--)
        {
            int j = Random.Range(0, i + 1);
            (shuffled[i], shuffled[j]) = (shuffled[j], shuffled[i]);
        }
        foreach (var card in shuffled) drawPile.Enqueue(card);
    }

    void DrawInitialHand()
    {
        for (int i = 0; i < 4; i++) DrawCard();
        UpdateNextCardPreview();
        RefreshHandUI();
    }

    void DrawCard()
    {
        if (drawPile.Count == 0) ReshuffleDeck();
        hand.Add(drawPile.Dequeue());
    }

    void ReshuffleDeck()
    {
        List<CardData> temp = new List<CardData>(deck);
        for (int i = temp.Count - 1; i > 0; i--)
        {
            int j = Random.Range(0, i + 1);
            (temp[i], temp[j]) = (temp[j], temp[i]);
        }
        foreach (var card in temp) drawPile.Enqueue(card);
    }

    // Called by UI button press (pass the card index 0-3)
    public void SelectCard(int index)
    {
        if (index < 0 || index >= hand.Count) return;
        selectedCardIndex = index;
    }

    // Called when player taps on the arena after selecting a card
    public void TryPlayCard(Vector2 screenPosition)
    {
        if (selectedCardIndex < 0) return;

        CardData card = hand[selectedCardIndex];

        if (!ElixirManager.Instance.Spend(card.elixirCost))
        {
            Debug.Log("Not enough elixir!");
            selectedCardIndex = -1;
            return;
        }

        Vector3 worldPos = arenaCamera.ScreenToWorldPoint(screenPosition);
        worldPos.z = 0;

        SpawnCard(card, worldPos);

        // Replace played card with a new one
        hand[selectedCardIndex] = drawPile.Count > 0 ? drawPile.Dequeue() : deck[0];
        selectedCardIndex = -1;

        UpdateNextCardPreview();
        RefreshHandUI();
    }

    void SpawnCard(CardData card, Vector3 position)
    {
        if (card.cardType == CardType.Spell)
        {
            // Damage all enemies in radius
            Collider2D[] hits = Physics2D.OverlapCircleAll(position, card.spellRadius);
            foreach (var hit in hits)
            {
                Unit u = hit.GetComponent<Unit>();
                if (u != null && u.ownerPlayerID != ownerPlayerID)
                    u.TakeDamage(card.spellDamage);

                Tower t = hit.GetComponent<Tower>();
                if (t != null && t.ownerPlayerID != ownerPlayerID)
                    t.TakeDamage(card.spellDamage);
            }
            return;
        }

        if (card.prefab == null) return;

        GameObject obj = Instantiate(card.prefab, position, Quaternion.identity);

        Unit unit = obj.GetComponent<Unit>();
        if (unit != null) unit.ownerPlayerID = ownerPlayerID;

        Tower building = obj.GetComponent<Tower>();
        if (building != null) building.ownerPlayerID = ownerPlayerID;
    }

    void RefreshHandUI()
    {
        for (int i = 0; i < cardImages.Length; i++)
        {
            if (i < hand.Count && hand[i] != null)
            {
                cardImages[i].sprite = hand[i].cardSprite;
                cardImages[i].color = Color.white;
                if (costTexts[i] != null)
                    costTexts[i].text = hand[i].elixirCost.ToString();
            }
        }
    }

    void UpdateNextCardPreview()
    {
        if (nextCardImage != null && drawPile.Count > 0)
            nextCardImage.sprite = drawPile.Peek().cardSprite;
    }
}

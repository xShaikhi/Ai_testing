using UnityEngine;
using UnityEngine.UI;
using TMPro;

// GameManager tracks crowns, timer, and win/loss conditions.
// Attach to a persistent GameObject in the Battle scene.
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    [Header("Game Settings")]
    public float gameDuration = 180f;    // 3 minutes
    public float overtimeDuration = 60f; // 1 minute overtime

    [Header("UI References")]
    public TextMeshProUGUI timerText;
    public TextMeshProUGUI player1CrownsText;
    public TextMeshProUGUI player2CrownsText;
    public GameObject gameOverPanel;
    public TextMeshProUGUI gameOverText;

    public int Player1Crowns { get; private set; }
    public int Player2Crowns { get; private set; }

    private float timeRemaining;
    private bool gameOver;
    private bool overtime;

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
    }

    void Start()
    {
        timeRemaining = gameDuration;
        UpdateUI();
    }

    void Update()
    {
        if (gameOver) return;

        timeRemaining -= Time.deltaTime;
        UpdateTimerUI();

        if (timeRemaining <= 0)
            OnTimeUp();
    }

    // Called by Tower when it is destroyed
    public void OnTowerDestroyed(Tower tower)
    {
        // Award crown to the opposing player
        if (tower.ownerPlayerID == 1)
            Player2Crowns++;
        else
            Player1Crowns++;

        UpdateCrownsUI();

        // King tower destroyed = instant win
        if (tower.isKingTower)
            EndGame(tower.ownerPlayerID == 1 ? 2 : 1);

        // 3 crowns = instant win
        if (Player1Crowns >= 3) EndGame(1);
        if (Player2Crowns >= 3) EndGame(2);
    }

    void OnTimeUp()
    {
        if (Player1Crowns != Player2Crowns)
        {
            EndGame(Player1Crowns > Player2Crowns ? 1 : 2);
            return;
        }

        if (!overtime)
        {
            overtime = true;
            timeRemaining = overtimeDuration;
            Debug.Log("Overtime!");
            return;
        }

        // Double overtime: sudden death - tie goes to draw
        EndGame(0);
    }

    void EndGame(int winnerPlayerID)
    {
        gameOver = true;
        if (gameOverPanel != null) gameOverPanel.SetActive(true);

        if (gameOverText != null)
        {
            gameOverText.text = winnerPlayerID == 0
                ? "Draw!"
                : $"Player {winnerPlayerID} Wins!";
        }

        ElixirManager.Instance.StopElixir();
    }

    void UpdateUI()
    {
        UpdateCrownsUI();
        UpdateTimerUI();
    }

    void UpdateCrownsUI()
    {
        if (player1CrownsText != null) player1CrownsText.text = Player1Crowns.ToString();
        if (player2CrownsText != null) player2CrownsText.text = Player2Crowns.ToString();
    }

    void UpdateTimerUI()
    {
        if (timerText == null) return;
        int minutes = Mathf.FloorToInt(timeRemaining / 60);
        int seconds = Mathf.FloorToInt(timeRemaining % 60);
        timerText.text = $"{minutes}:{seconds:00}";
    }
}

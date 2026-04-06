using UnityEngine;
using UnityEngine.UI;

// Manages elixir generation over time.
// Attach to a persistent GameObject alongside GameManager.
public class ElixirManager : MonoBehaviour
{
    public static ElixirManager Instance { get; private set; }

    [Header("Elixir Settings")]
    [Range(1f, 10f)]
    public float maxElixir = 10f;
    public float elixirPerSecond = 1f;      // normal rate
    public float overtimeMultiplier = 2f;   // x2 in overtime

    [Header("UI")]
    public Slider elixirBar;
    public UnityEngine.UI.Text elixirText;   // optional numeric display

    public float CurrentElixir { get; private set; } = 5f;

    private bool running = true;
    private bool overTimeActive = false;

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
    }

    void Start()
    {
        UpdateUI();
    }

    void Update()
    {
        if (!running) return;

        float rate = overTimeActive ? elixirPerSecond * overtimeMultiplier : elixirPerSecond;
        CurrentElixir = Mathf.Min(maxElixir, CurrentElixir + rate * Time.deltaTime);
        UpdateUI();
    }

    // Returns true and deducts cost if there is enough elixir; false otherwise.
    public bool Spend(int cost)
    {
        if (CurrentElixir < cost) return false;
        CurrentElixir -= cost;
        UpdateUI();
        return true;
    }

    public void ActivateOvertime()
    {
        overTimeActive = true;
    }

    public void StopElixir()
    {
        running = false;
    }

    void UpdateUI()
    {
        if (elixirBar != null)
            elixirBar.value = CurrentElixir / maxElixir;

        if (elixirText != null)
            elixirText.text = Mathf.FloorToInt(CurrentElixir).ToString();
    }
}

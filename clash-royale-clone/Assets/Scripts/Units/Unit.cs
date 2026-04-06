using UnityEngine;
using UnityEngine.UI;

public enum UnitTarget { Ground, Air, Both, Buildings }
public enum UnitType { Ground, Air }

public class Unit : MonoBehaviour
{
    [Header("Unit Stats")]
    public string unitName = "Knight";
    public int maxHealth = 600;
    public int attackDamage = 100;
    public float attackRange = 1f;
    public float attackSpeed = 1f;       // attacks per second
    public float moveSpeed = 2f;
    public UnitTarget targetType = UnitTarget.Ground;
    public UnitType unitType = UnitType.Ground;

    [Header("Owner")]
    public int ownerPlayerID = 1;        // 1 or 2

    [Header("UI")]
    public Slider healthBar;

    public int CurrentHealth { get; private set; }
    public bool IsDestroyed { get; private set; }

    private UnitAI ai;

    void Start()
    {
        CurrentHealth = maxHealth;
        ai = GetComponent<UnitAI>();
        UpdateHealthBar();
    }

    public void TakeDamage(int damage)
    {
        if (IsDestroyed) return;

        CurrentHealth -= damage;
        CurrentHealth = Mathf.Max(0, CurrentHealth);
        UpdateHealthBar();

        if (CurrentHealth <= 0)
            Die();
    }

    void Die()
    {
        IsDestroyed = true;
        Destroy(gameObject, 0.5f);
    }

    void UpdateHealthBar()
    {
        if (healthBar != null)
            healthBar.value = (float)CurrentHealth / maxHealth;
    }
}

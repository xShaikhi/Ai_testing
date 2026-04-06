using UnityEngine;
using UnityEngine.UI;

public class Tower : MonoBehaviour
{
    [Header("Tower Stats")]
    public string towerName = "Guard Tower";
    public int maxHealth = 3000;
    public int attackDamage = 100;
    public float attackRange = 5f;
    public float attackSpeed = 1f;   // attacks per second
    public bool isKingTower = false;

    [Header("Owner")]
    public int ownerPlayerID = 1;    // 1 or 2

    [Header("UI")]
    public Slider healthBar;
    public GameObject destroyedSprite;

    public int CurrentHealth { get; private set; }
    public bool IsDestroyed { get; private set; }

    private float attackTimer;
    private Unit currentTarget;

    void Start()
    {
        CurrentHealth = maxHealth;
        UpdateHealthBar();
    }

    void Update()
    {
        if (IsDestroyed) return;

        attackTimer += Time.deltaTime;

        if (currentTarget == null || currentTarget.IsDestroyed)
            FindTarget();

        if (currentTarget != null && attackTimer >= 1f / attackSpeed)
        {
            Attack(currentTarget);
            attackTimer = 0f;
        }
    }

    void FindTarget()
    {
        currentTarget = null;
        float closestDistance = attackRange;

        Unit[] allUnits = FindObjectsOfType<Unit>();
        foreach (Unit unit in allUnits)
        {
            if (unit.ownerPlayerID == ownerPlayerID || unit.IsDestroyed)
                continue;

            float distance = Vector2.Distance(transform.position, unit.transform.position);
            if (distance < closestDistance)
            {
                closestDistance = distance;
                currentTarget = unit;
            }
        }
    }

    void Attack(Unit target)
    {
        target.TakeDamage(attackDamage);
    }

    public void TakeDamage(int damage)
    {
        if (IsDestroyed) return;

        CurrentHealth -= damage;
        CurrentHealth = Mathf.Max(0, CurrentHealth);
        UpdateHealthBar();

        if (CurrentHealth <= 0)
            DestroyTower();
    }

    void DestroyTower()
    {
        IsDestroyed = true;
        if (destroyedSprite != null) destroyedSprite.SetActive(true);
        GetComponent<SpriteRenderer>().enabled = false;

        GameManager.Instance.OnTowerDestroyed(this);
    }

    void UpdateHealthBar()
    {
        if (healthBar != null)
            healthBar.value = (float)CurrentHealth / maxHealth;
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, attackRange);
    }
}

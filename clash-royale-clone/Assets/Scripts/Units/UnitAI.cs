using UnityEngine;

// UnitAI handles movement and attack logic for a unit.
// Priority: enemy units > enemy towers (nearest first)
public class UnitAI : MonoBehaviour
{
    private Unit unit;
    private float attackTimer;
    private Component currentTarget;     // Unit or Tower

    void Start()
    {
        unit = GetComponent<Unit>();
    }

    void Update()
    {
        if (unit.IsDestroyed) return;

        attackTimer += Time.deltaTime;

        FindTarget();

        if (currentTarget == null)
        {
            MoveForward();
            return;
        }

        float distance = Vector2.Distance(transform.position, ((Component)currentTarget).transform.position);

        if (distance > unit.attackRange)
            MoveToward(((Component)currentTarget).transform.position);
        else if (attackTimer >= 1f / unit.attackSpeed)
        {
            AttackTarget();
            attackTimer = 0f;
        }
    }

    void FindTarget()
    {
        // Try to find the nearest enemy unit first
        Unit nearestUnit = FindNearestEnemyUnit();
        if (nearestUnit != null)
        {
            currentTarget = nearestUnit;
            return;
        }

        // Fall back to nearest enemy tower
        currentTarget = FindNearestEnemyTower();
    }

    Unit FindNearestEnemyUnit()
    {
        Unit nearest = null;
        float minDist = float.MaxValue;

        foreach (Unit u in FindObjectsOfType<Unit>())
        {
            if (u == unit || u.ownerPlayerID == unit.ownerPlayerID || u.IsDestroyed)
                continue;

            // Skip air units if this unit can only hit ground
            if (unit.targetType == UnitTarget.Ground && u.unitType == UnitType.Air) continue;
            if (unit.targetType == UnitTarget.Air && u.unitType == UnitType.Ground) continue;

            float d = Vector2.Distance(transform.position, u.transform.position);
            if (d < minDist) { minDist = d; nearest = u; }
        }

        return nearest;
    }

    Tower FindNearestEnemyTower()
    {
        Tower nearest = null;
        float minDist = float.MaxValue;

        foreach (Tower t in FindObjectsOfType<Tower>())
        {
            if (t.ownerPlayerID == unit.ownerPlayerID || t.IsDestroyed)
                continue;

            float d = Vector2.Distance(transform.position, t.transform.position);
            if (d < minDist) { minDist = d; nearest = t; }
        }

        return nearest;
    }

    void AttackTarget()
    {
        if (currentTarget is Unit targetUnit)
            targetUnit.TakeDamage(unit.attackDamage);
        else if (currentTarget is Tower targetTower)
            targetTower.TakeDamage(unit.attackDamage);
    }

    void MoveToward(Vector3 target)
    {
        transform.position = Vector2.MoveTowards(
            transform.position,
            target,
            unit.moveSpeed * Time.deltaTime
        );
        FaceTarget(target);
    }

    void MoveForward()
    {
        // Player 1 moves right (+x), Player 2 moves left (-x)
        float direction = unit.ownerPlayerID == 1 ? 1f : -1f;
        transform.Translate(Vector2.right * direction * unit.moveSpeed * Time.deltaTime);
    }

    void FaceTarget(Vector3 target)
    {
        Vector3 scale = transform.localScale;
        scale.x = target.x < transform.position.x ? -Mathf.Abs(scale.x) : Mathf.Abs(scale.x);
        transform.localScale = scale;
    }
}

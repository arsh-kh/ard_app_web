<RULE[user_global]>
# ARD App Domain Rules

## 1. Profit Calculation Constraint
- **Rule:** Do NOT modify, "correct", or refactor the top-level Profit calculation metric on the Dashboard (currently `Profit = Revenue - Purchases`).
- **Rationale:** The business explicitly requires this metric to represent Cash Flow (Revenue minus total inventory purchased) rather than a standard Cost of Goods Sold (COGS) profit margin.

## 2. Terminology Constraints
- **Rule:** Never use the word "discount" when referring to price adjustments at checkout.
- **Replacement:** Always use the term **"custom pricing override"** or **"edit price in checkout"**.
- **Rationale:** The application does not apply traditional discounts; it allows the user to explicitly override the price for a specific customer, which can be either higher or lower than the base price.
</RULE[user_global]>

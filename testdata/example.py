# Order processing pipeline
# Reads orders, applies discounts, and generates a summary report

from dataclasses import dataclass
from typing import Optional

DISCOUNT_TIERS = {
    "gold": 0.15,
    "silver": 0.10,
    "bronze": 0.05,
}

TAX_RATE = 0.08


@dataclass
class OrderItem:
    sku: str
    name: str
    unit_price: float
    quantity: int


@dataclass
class Order:
    order_id: str
    customer: str
    tier: str
    items: list[OrderItem]
    shipping: float = 5.99


def load_sample_orders() -> list[Order]:
    """Return a handful of dummy orders for testing."""
    return [
        Order("ORD-001", "Acme Corp", "gold", [
            OrderItem("SKU-100", "Widget A", 19.99, 10),
            OrderItem("SKU-101", "Widget B", 7.50, 25),
        ]),
        Order("ORD-002", "Beta LLC", "silver", [
            OrderItem("SKU-200", "Gadget X", 149.00, 2),
            OrderItem("SKU-201", "Gadget Y", 89.95, 1),
        ], shipping=12.50),
        Order("ORD-003", "Gamma Inc", "bronze", [
            OrderItem("SKU-300", "Part Z", 4.25, 100),
        ]),
    ]


def calc_subtotal(order: Order) -> float:
    return sum(item.unit_price * item.quantity for item in order.items)


def apply_discount(subtotal: float, tier: str) -> float:
    rate = DISCOUNT_TIERS.get(tier, 0)
    return subtotal * (1 - rate)


def calc_total(order: Order) -> float:
    subtotal = calc_subtotal(order)
    after_discount = apply_discount(subtotal, order.tier)
    tax = after_discount * TAX_RATE
    return round(after_discount + tax + order.shipping, 2)


def generate_report(orders: list[Order]) -> None:
    print("=== Order Summary Report ===\n")
    grand_total = 0.0
    for order in orders:
        total = calc_total(order)
        grand_total += total
        print(f"{order.order_id} | {order.customer:<12} | tier={order.tier:<6} | total=${total:.2f}")
    print(f"\nGrand total across {len(orders)} orders: ${grand_total:.2f}")


if __name__ == "__main__":
    orders = load_sample_orders()
    generate_report(orders)

package com.example.inventory;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Simple inventory management system.
 * Tracks products with stock levels and pricing.
 */
public class Example {

    private final List<Product> products = new ArrayList<>();

    // Inner class representing a product in the inventory
    static class Product {
        int id;
        String name;
        String category;
        double price;
        int quantity;

        Product(int id, String name, String category, double price, int quantity) {
            this.id = id;
            this.name = name;
            this.category = category;
            this.price = price;
            this.quantity = quantity;
        }

        @Override
        public String toString() {
            return String.format("[%d] %s - $%.2f (%d in stock)", id, name, price, quantity);
        }
    }

    // Load some sample products into the inventory
    public void loadSampleData() {
        products.add(new Product(101, "Wireless Mouse", "Electronics", 29.99, 150));
        products.add(new Product(102, "USB-C Hub", "Electronics", 49.95, 80));
        products.add(new Product(103, "Standing Desk Mat", "Office", 34.50, 200));
        products.add(new Product(104, "Notebook 3-Pack", "Office", 12.99, 500));
        products.add(new Product(105, "LED Desk Lamp", "Lighting", 42.00, 60));
    }

    // Find a product by its ID
    public Optional<Product> findById(int id) {
        return products.stream()
                .filter(p -> p.id == id)
                .findFirst();
    }

    // Get all products in a given category
    public List<Product> getByCategory(String category) {
        return products.stream()
                .filter(p -> p.category.equalsIgnoreCase(category))
                .collect(Collectors.toList());
    }

    // Calculate total value of all inventory
    public double getTotalInventoryValue() {
        return products.stream()
                .mapToDouble(p -> p.price * p.quantity)
                .sum();
    }

    // Reduce stock for a product after a sale
    public boolean sellProduct(int id, int qty) {
        Optional<Product> product = findById(id);
        if (product.isPresent() && product.get().quantity >= qty) {
            product.get().quantity -= qty;
            return true;
        }
        return false;
    }

    public static void main(String[] args) {
        Example inventory = new Example();
        inventory.loadSampleData();

        System.out.println("Electronics:");
        inventory.getByCategory("Electronics").forEach(System.out::println);

        System.out.printf("Total inventory value: $%.2f%n", inventory.getTotalInventoryValue());

        inventory.sellProduct(101, 5);
        System.out.println("After selling 5 mice: " + inventory.findById(101).orElse(null));
    }
}

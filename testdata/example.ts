// User management service for handling CRUD operations
// Uses in-memory store for demo purposes

interface User {
  id: number;
  name: string;
  email: string;
  role: "admin" | "editor" | "viewer";
  createdAt: Date;
}

interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
}

const users: User[] = [
  { id: 1, name: "Alice Johnson", email: "alice@example.com", role: "admin", createdAt: new Date("2025-03-10") },
  { id: 2, name: "Bob Smith", email: "bob@example.com", role: "editor", createdAt: new Date("2025-06-22") },
  { id: 3, name: "Carol White", email: "carol@example.com", role: "viewer", createdAt: new Date("2025-09-01") },
];

// Fetch all users, optionally filtered by role
function getUsers(role?: User["role"]): ApiResponse<User[]> {
  const filtered = role ? users.filter((u) => u.role === role) : users;
  return { success: true, data: filtered };
}

// Find a single user by ID
function getUserById(id: number): ApiResponse<User | null> {
  const user = users.find((u) => u.id === id) ?? null;
  if (!user) {
    return { success: false, data: null, message: `User ${id} not found` };
  }
  return { success: true, data: user };
}

// Add a new user and return the created record
function createUser(name: string, email: string, role: User["role"]): ApiResponse<User> {
  const newUser: User = {
    id: Math.max(...users.map((u) => u.id)) + 1,
    name,
    email,
    role,
    createdAt: new Date(),
  };
  users.push(newUser);
  return { success: true, data: newUser, message: "User created" };
}

// Calculate some basic stats across the user base
function getUserStats(): Record<string, number> {
  return {
    total: users.length,
    admins: users.filter((u) => u.role === "admin").length,
    editors: users.filter((u) => u.role === "editor").length,
    viewers: users.filter((u) => u.role === "viewer").length,
  };
}

export { getUsers, getUserById, createUser, getUserStats };

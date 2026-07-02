# Seeds for Event Manager System

alias EventManager.Core
alias EventManager.Repo

# Create admin user
{:ok, admin} = Core.register_admin(%{
  email: "admin@eventmanager.com",
  name: "Administrador do Sistema",
  password: "Admin@123",
  course: "Ciência da Computação",
  department: "Departamento de Computação"
})

IO.puts("Seed data created successfully!")
IO.puts("Admin: admin@eventmanager.com / Admin@123")
.PHONY: help setup ssh-keys vault-password vault build up down shell clean test

# Variables
SSH_KEY_DIR := ansible-init/ssh_keys
SSH_KEY_NAME := playground
SSH_KEY_PATH := $(SSH_KEY_DIR)/$(SSH_KEY_NAME)
VAULT_PASSWORD_FILE := .vault_password
VAULT_FILE := vault.yml
DOCKER_COMPOSE := docker-compose
COMPOSE_FILE := ansible-init/docker-compose.yml
CONTAINER_NAME := ansible-server

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Ansible Playground Setup Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

setup: ssh-keys vault-password vault build up ## Complete setup: generate SSH keys, create vault files, and start containers
	@echo ""
	@echo "✓ Setup complete!"
	@echo ""
	@echo "To access the ansible-server container, run:"
	@echo "  make shell"
	@echo ""
	@echo "To run a sample playbook:"
	@echo "  docker exec -it $(CONTAINER_NAME) ansible-playbook playbooks/echo.yml -i hosts/inventory"

ssh-keys: ## Generate SSH keys for container authentication
	@echo "Setting up SSH keys..."
	@if [ ! -d "$(SSH_KEY_DIR)" ]; then \
		mkdir -p $(SSH_KEY_DIR); \
		echo "Created directory: $(SSH_KEY_DIR)"; \
	fi
	@if [ ! -f "$(SSH_KEY_PATH)" ]; then \
		echo "Generating SSH key pair..."; \
		ssh-keygen -t rsa -b 4096 -f $(SSH_KEY_PATH) -N "" -C "ansible-playground"; \
		echo "✓ SSH keys generated at $(SSH_KEY_PATH)"; \
	else \
		echo "✓ SSH keys already exist at $(SSH_KEY_PATH)"; \
	fi

vault-password: ## Create vault password file (interactive)
	@echo "Setting up Ansible vault password..."
	@if [ ! -f "$(VAULT_PASSWORD_FILE)" ]; then \
		echo "Enter password for Ansible vault (will be saved to $(VAULT_PASSWORD_FILE)):"; \
		read -s password; \
		echo "$$password" > $(VAULT_PASSWORD_FILE); \
		chmod 600 $(VAULT_PASSWORD_FILE); \
		echo "✓ Vault password saved to $(VAULT_PASSWORD_FILE)"; \
	else \
		echo "✓ Vault password file already exists at $(VAULT_PASSWORD_FILE)"; \
	fi

vault: vault-password ## Create Ansible vault file (interactive)
	@echo "Setting up Ansible vault file..."
	@if [ ! -f "$(VAULT_FILE)" ]; then \
		echo "Creating vault file: $(VAULT_FILE)"; \
		if [ -f "$(VAULT_PASSWORD_FILE)" ]; then \
			echo "Using vault password from $(VAULT_PASSWORD_FILE)"; \
			ansible-vault create $(VAULT_FILE) --vault-password-file $(VAULT_PASSWORD_FILE) || \
			ansible-vault create $(VAULT_FILE); \
		else \
			echo "Enter vault password:"; \
			ansible-vault create $(VAULT_FILE); \
		fi; \
		echo "✓ Vault file created at $(VAULT_FILE)"; \
	else \
		echo "✓ Vault file already exists at $(VAULT_FILE)"; \
	fi

build: ssh-keys ## Build Docker containers
	@echo "Building Docker containers..."
	@cd ansible-init && $(DOCKER_COMPOSE) build
	@echo "✓ Docker containers built successfully"

build-clean: ssh-keys ## Build Docker containers from scratch (no cache)
	@echo "Building Docker containers (clean build)..."
	@cd ansible-init && $(DOCKER_COMPOSE) build --no-cache
	@echo "✓ Docker containers built successfully"

rebuild-slave2: ssh-keys ## Rebuild only slave2 container (fixes Python 3.8 compatibility)
	@echo "Rebuilding slave2 container..."
	@cd ansible-init && $(DOCKER_COMPOSE) build --no-cache slave2
	@echo "✓ slave2 container rebuilt successfully"

rebuild-slave1: ssh-keys ## Rebuild only slave1 container (fixes Python 3.8 compatibility)
	@echo "Rebuilding slave1 container..."
	@cd ansible-init && $(DOCKER_COMPOSE) build --no-cache slave1
	@echo "✓ slave1 container rebuilt successfully"

up: build ## Start Docker containers
	@echo "Starting Docker containers..."
	@cd ansible-init && $(DOCKER_COMPOSE) up -d
	@echo "Waiting for containers to be ready..."
	@sleep 5
	@echo "✓ Docker containers started successfully"
	@echo ""
	@echo "Running containers:"
	@cd ansible-init && $(DOCKER_COMPOSE) ps

down: ## Stop Docker containers
	@echo "Stopping Docker containers..."
	@cd ansible-init && $(DOCKER_COMPOSE) down
	@echo "✓ Docker containers stopped"

restart: down up ## Restart Docker containers

shell: ## Access ansible-server container shell
	@echo "Accessing $(CONTAINER_NAME) container..."
	@docker exec -it $(CONTAINER_NAME) bash || \
		echo "Error: Container $(CONTAINER_NAME) is not running. Run 'make up' first."

logs: ## Show Docker container logs
	@cd ansible-init && $(DOCKER_COMPOSE) logs -f

test: ## Run sample echo playbook
	@echo "Running sample playbook: playbooks/echo.yml"
	@docker exec -it $(CONTAINER_NAME) ansible-playbook playbooks/echo.yml -i hosts/inventory || \
		echo "Error: Container $(CONTAINER_NAME) is not running. Run 'make up' first."

clean: down ## Clean up generated files (keeps SSH keys and vault files)
	@echo "Cleaning up..."
	@cd ansible-init && $(DOCKER_COMPOSE) down --rmi local --volumes --remove-orphans
	@echo "✓ Cleanup complete"

clean-all: clean ## Clean up everything including SSH keys and vault files (WARNING: destructive)
	@echo "WARNING: This will remove SSH keys and vault files!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -rf $(SSH_KEY_DIR); \
		rm -f $(VAULT_PASSWORD_FILE) $(VAULT_FILE); \
		echo "✓ All files cleaned up"; \
	else \
		echo "Cleanup cancelled"; \
	fi

status: ## Show status of containers and required files
	@echo "=== Ansible Playground Status ==="
	@echo ""
	@echo "Required Files:"
	@[ -f "$(SSH_KEY_PATH)" ] && echo "  ✓ SSH keys exist" || echo "  ✗ SSH keys missing (run: make ssh-keys)"
	@[ -f "$(VAULT_PASSWORD_FILE)" ] && echo "  ✓ Vault password exists" || echo "  ✗ Vault password missing (run: make vault-password)"
	@[ -f "$(VAULT_FILE)" ] && echo "  ✓ Vault file exists" || echo "  ✗ Vault file missing (run: make vault)"
	@echo ""
	@echo "Docker Containers:"
	@cd ansible-init && $(DOCKER_COMPOSE) ps || echo "  No containers running"


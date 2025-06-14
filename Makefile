# Get INSTALL_USER from config.sh
INSTALL_USER := $(shell grep '^export INSTALL_USER=' config.sh | cut -d'"' -f2 | head -1)

# Declare all phony targets
.PHONY: info all prepare automount symlinks copy_dirs repos apps misc post_restart update

# Just the name
info:
	@echo '=================================================='
	@echo '          Linux Post Install Script'
	@echo '=================================================='

# Run all steps in sequence
all: prepare automount symlinks copy_dirs repos apps misc update post_restart
	@echo '=================================================='
	@echo '          All installation steps completed'
	@echo '=================================================='

# Make scripts executable
prepare:
	@echo '=================================================='
	@echo '          Making scripts executable'
	@echo '=================================================='
	@sudo find ./ -type f -name "*.sh" -exec chmod +x {} \;

# Automount drives
automount:
	@echo '=================================================='
	@echo '          Setting up drive automounting'
	@echo '=================================================='
	@./scripts/automount.sh create
	@sudo ./scripts/automount.sh mount

# Create symlinks
symlinks:
	@echo '=================================================='
	@echo '          Creating symlinks'
	@echo '=================================================='
	@./scripts/create_symlinks.sh

# Copy directories
copy_dirs:
	@echo '=================================================='
	@echo '          Copying directories'
	@echo '=================================================='
	@./scripts/copy_dirs.sh

# Add repositories
repos:
	@echo '=================================================='
	@echo '          Adding repositories'
	@echo '=================================================='
	@sudo -u ${INSTALL_USER} ./scripts/add_repositories.sh

# Install applications
apps: repos
	@echo '=================================================='
	@echo '          Installing applications'
	@echo '=================================================='
	@sudo -u ${INSTALL_USER} ./scripts/install_apps.sh

# Miscellaneous settings
misc: apps
	@echo '=================================================='
	@echo '          Configuring misc settings'
	@echo '=================================================='
	@sudo -u ${INSTALL_USER} ./scripts/misc.sh
	@sudo -u ${INSTALL_USER} ./scripts/misc_user.sh

# Update system
update:
	@echo '=================================================='
	@echo '          Updating system'
	@echo '=================================================='
	@sudo -u ${INSTALL_USER} ./scripts/update.sh

# Post-restart operations
post_restart:
	@echo '=================================================='
	@echo '          Running post-restart operations'
	@echo '=================================================='
	@./scripts/post_restart.sh 
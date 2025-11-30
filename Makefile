# Makefile
# =========================================
# Project: sphinx-cookiecutter
# =========================================

# --------------------------------------------------
# ⚙️ Environment Settings
# --------------------------------------------------
SHELL := /bin/bash
.SHELLFLAGS := -O globstar -c
# If V is set to '1' or 'y' on the command line,
# AT will be empty (verbose).  Otherwise, AT will
# contain '@' (quiet by default).  The '?' is a
# conditional assignment operator: it only sets V
# if it hasn't been set externally.
V ?= 0
ifeq ($(V),0)
    AT = @
else
    AT =
endif
# Detect if we are running inside GitHub Actions CI.
# GitHub sets the environment variable GITHUB_ACTIONS=true in workflows.
# We set CI=1 if running in GitHub Actions, otherwise CI=0 for local runs.
ifeq ($(GITHUB_ACTIONS),true)
CI := 1
else
CI := 0
endif
# Define a reusable CI-safe runner
define run_ci_safe =
( $1 || [ "$(CI)" != "1" ] )
endef
# --------------------------------------------------
# ⚙️ Build Settings
# --------------------------------------------------
PACKAGE_NAME := "sphinx-cookiecutter"
PACKAGE_AUTHOR := "Jared Cook"
PACKAGE_VERSION := "0.1.0"
# --------------------------------------------------
# 📁 Build Directories
# --------------------------------------------------
PROJECT_ROOT := $(PWD)
COOKIE_DIR := $(PROJECT_ROOT)/"{{ cookiecutter.project_name }}"
SRC_DIR := $(COOKIE_DIR)
HOOKS_DIR := $(PROJECT_ROOT)/hooks
TESTS_DIR := $(PROJECT_ROOT)/tests
DOCS_DIR := $(PROJECT_ROOT)/docs
SPHINX_DIR := $(DOCS_DIR)/sphinx
JEKYLL_DIR := $(DOCS_DIR)/jekyll
JEKYLL_SPHINX_DIR := $(JEKYLL_DIR)/sphinx
README_GEN_DIR := $(JEKYLL_DIR)/tmp_readme
# --------------------------------------------------
# 🐍 Python / Virtual Environment
# --------------------------------------------------
PYTHON_CMD := python3.11
VENV_DIR := .venv
# --------------------------------------------------
# 🐍 Python Dependencies
# --------------------------------------------------
DEPS := .
DEV_DEPS := .[dev]
DEV_DOCS := .[docs]
# --------------------------------------------------
# 🐍 Python Commands (venv, activate, pip)
# --------------------------------------------------
CREATE_VENV := $(PYTHON_CMD) -m venv $(VENV_DIR)
ACTIVATE := source $(VENV_DIR)/bin/activate
PYTHON := $(ACTIVATE) && $(PYTHON_CMD)
PIP := $(PYTHON) -m pip
# --------------------------------------------------
# 🧠 Typing (mypy)
# --------------------------------------------------
MYPY := $(PYTHON) -m mypy
# --------------------------------------------------
# 🎨 Formatting (black)
# --------------------------------------------------
BLACK := $(PYTHON) -m black
# --------------------------------------------------
# 🔍 Linting (ruff, yaml, jinja2)
# --------------------------------------------------
RUFF := $(PYTHON) -m ruff
YAMLLINT := $(PYTHON) -m yamllint
JINJA := $(ACTIVATE) && jinja2 --strict
# --------------------------------------------------
# 🧪 Testing (pytest)
# --------------------------------------------------
PYTEST := $(PYTHON) -m pytest
# --------------------------------------------------
# 📘 Documentation (Sphinx + Jekyll)
# --------------------------------------------------
SPHINX := $(PYTHON) -m sphinx -b markdown
JEKYLL_BUILD := bundle exec jekyll build
JEKYLL_CLEAN := bundle exec jekyll clean
JEKYLL_SERVE := bundle exec jekyll serve
# --------------------------------------------------
# 🔖 Version Bumping (bumpy-my-version)
# --------------------------------------------------
BUMPVERSION := bump-my-version bump --verbose
# Patch types:
MAJOR := major
MINOR := minor
PATCH := patch
# --------------------------------------------------
.PHONY: all venv install ruff-lint-check ruff-lint-fix yaml-lint-check \
	jinja2-lint-check lint-check typecheck test sphinx jekyll readme build-docs \
	jekyll-serve run-docs clean help
# --------------------------------------------------
# Default: run lint, typecheck, tests, and build-docs
# --------------------------------------------------
all: install lint-check typecheck test build-docs
# --------------------------------------------------
# 🐍 Virtual Environment Setup
# --------------------------------------------------
venv:
	$(AT)echo "🐍 Creating virtual environment..."
	$(AT)$(CREATE_VENV)
	$(AT)echo "✅ Virtual environment created."

install: venv
	$(AT)echo "📦 Installing project dependencies..."
	$(AT)$(PIP) install --upgrade pip
	$(AT)$(PIP) install -e $(DEPS)
	$(AT)$(PIP) install -e $(DEV_DEPS)
	$(AT)$(PIP) install -e $(DEV_DOCS)
	$(AT)echo "✅ Dependencies installed."
# --------------------------------------------------
# 🎨 Formatting (black)
# --------------------------------------------------
black-formatter-check:
	$(AT)echo "🔍 Running black formatter style check..."
	$(AT)$(call run_ci_safe, $(BLACK) --check $(SRC_DIR) $(TESTS_DIR))
	$(AT)echo "✅ Finished formatting check of Python code with Black!"
	
black-formatter-fix:
	$(AT)echo "🎨 Running black formatter fixes..."
	$(AT)$(BLACK) $(SRC_DIR) $(TESTS_DIR)
	$(AT)echo "✅ Finished formatting Python code with Black!"

format-check: black-formatter-check
format-fix: black-formatter-fix
# --------------------------------------------------
# 🔍 Linting (ruff, yaml, jinja2)
# --------------------------------------------------
ruff-lint-check:
	$(AT)echo "🔍 Running ruff linting..."
	$(AT)$(RUFF) check $(SRC_DIR) $(TESTS_DIR)
	$(AT)echo "✅ Finished linting check of Python code with Ruff!"

ruff-lint-fix:
	$(AT)echo "🎨 Running ruff lint fixes..."
	$(AT)$(RUFF) check --show-files $(SRC_DIR) $(TESTS_DIR)
	$(AT)$(RUFF) check --fix $(SRC_DIR) $(TESTS_DIR)
	$(AT)echo "✅ Finished linting Python code with Ruff!"

yaml-lint-check:
	$(AT)echo "🔍 Running yamllint..."
	$(AT)$(YAMLLINT) .
	$(AT)echo "✅ Finished linting check of yaml files with yamllint!"

jinja2-lint-check:
	$(AT)echo "🔍 jinja2 linting all template files under $(SRC_DIR)..."
	$(AT)jq '{cookiecutter: .}' cookiecutter.json > /tmp/_cc_wrapped.json
	$(AT)find $(SRC_DIR) -type f \
		! -path $(SRC_DIR)/.github/* \
		! -name "*.md"   \
		! -name "*.html" \
		! -name "*.png"  \
		! -name "*.jpg"  \
		! -name "*.ico"  \
		! -name "*.gif"  \
		-print0 | while IFS= read -r -d '' f; do \
			if file "$$f" | grep -q text; then \
				echo "Checking $$f"; \
				$(JINJA) "$$f" /tmp/_cc_wrapped.json || exit 1; \
			fi; \
		done
	$(AT)echo "✅ Finished linting check of jinja2 files with jinja2!"

lint-check: ruff-lint-check yaml-lint-check jinja2-lint-check
lint-fix: ruff-lint-fix
# --------------------------------------------------
# 🧠 Typechecking (MyPy)
# --------------------------------------------------
typecheck:
	$(AT)echo "🧠 Checking types (MyPy)..."
	$(AT)$(MYPY) $(SRC_DIR) $(TESTS_DIR)
	$(AT)echo "✅ Python typecheck complete!"
# --------------------------------------------------
# 🧪 Testing (pytest)
# --------------------------------------------------
test:
	$(AT)echo "🧪 Running tests with pytest..."
	$(AT)$(PYTEST) $(TESTS_DIR)
	$(AT)echo "✅ Python tests complete!"
# --------------------------------------------------
# 📘 Documentation (Sphinx + Jekyll)
# --------------------------------------------------
sphinx:
	$(AT)echo "🔨 Building Sphinx documentation 📘 as Markdown..."
	$(AT)$(SPHINX) $(SPHINX_DIR) $(JEKYLL_SPHINX_DIR)
	$(AT)echo "✅ Sphinx Markdown build complete!"

jekyll:
	$(AT)echo "🔨 Building Jekyll site..."
	$(AT)cd $(JEKYLL_DIR) && $(JEKYLL_BUILD)
	$(AT)echo "✅ Full documentation build complete!"

build-docs: sphinx jekyll

jekyll-serve: docs
	$(AT)echo "🚀 Starting Jekyll development server..."
	$(AT)cd $(JEKYLL_DIR) && $(JEKYLL_SERVE)

run-docs: jekyll-serve
# --------------------------------------------------
# 🔖 Version Bumping (bumpy-my-version)
# --------------------------------------------------
# TODO: Also create a git tag of current version.
bump-version-patch:
	$(AT)echo "🔖 Updating $(PACKAGE_NAME) version from $(VERSION)..."
	$(AT)$(BUMPVERSION) $(PATCH)
	$(AT)echo "✅ $(PACKAGE_NAME) version update complete!"
# --------------------------------------------------
# 🧹 Clean artifacts
# --------------------------------------------------
clean:
	$(AT)echo "🧹 Clening build artifacts..."
	$(AT)rm -rf $(SPHINX_DIR)/_build $(JEKYLL_SPHINX_DIR)
	$(AT)cd $(JEKYLL_DIR) && $(JEKYLL_CLEAN)
	$(AT)rm -rf build dist *.egg-info
	$(AT)find $(HOOKS_DIR) $(TESTS_DIR) -name "__pycache__" -type d -exec rm -rf {} +
	$(AT)-[ -d "$(VENV_DIR)" ] && rm -r $(VENV_DIR)
	$(AT)echo "🧹 Cleaned build artifacts."
# --------------------------------------------------
# Help
# --------------------------------------------------
help:
	$(AT)echo "📦 sphinx-cookiecutter Makefile"
	$(AT)echo ""
	$(AT)echo "Usage:"
	$(AT)echo "  make venv                   Create virtual environment"
	$(AT)echo "  make install                Install dependencies"
	$(AT)echo "  make black-formatter-check  Run Black formatter check"
	$(AT)echo "  make black-formatter-fix    Run Black formatter"
	$(AT)echo "  make format-check           Run all project formatter checks (black)"
	$(AT)echo "  make format-fix             Run all project formatter autofixes (black)"
	$(AT)echo "  make ruff-lint-check        Run Ruff linter"
	$(AT)echo "  make ruff-lint-fix          Auto-fix lint issues with python ruff"
	$(AT)echo "  make yaml-lint-check        Run YAML linter"
	$(AT)echo "  make jinja2-lint-check      Run jinja-cmd linter"
	$(AT)echo "  make lint-check             Run all project linters (ruff, yaml, & jinja2)"
	$(AT)echo "  make typecheck              Run Mypy type checking"
	$(AT)echo "  make test                   Run Pytest suite"
	$(AT)echo "  make sphinx                 Generate Sphinx Documentation"
	$(AT)echo "  make jekyll                 Generate Jekyll Documentation"
	$(AT)echo "  make build-docs             Build Sphinx + Jekyll documentation"
	$(AT)echo "  make run-docs               Serve Jekyll site locally"
	$(AT)echo "  make clean                  Clean build artifacts"
	$(AT)echo "  make all                    Run install, lint, typecheck, test, and docs"
	$(AT)echo "Options:"
	$(AT)echo "  V=1             Enable verbose output (show all commands being executed)"
	$(AT)echo "  make -s         Run completely silently (suppress make's own output AND command echo)"

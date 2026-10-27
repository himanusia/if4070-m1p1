SHELL := /bin/bash
GROUP := $(shell python3 -c "import yaml;print(yaml.safe_load(open('config.yaml'))['grup'])" 2>/dev/null || echo KXX)

JAVA_HOME := $(HOME)/.hermes/tools/jdk/jdk-21.0.13+9/Contents/Home
JAVA      := $(JAVA_HOME)/bin/java
ROBOT     := $(HOME)/.hermes/tools/robot.jar
PROTEGE   := $(HOME)/.hermes/tools/protege/Protege-5.6.9/Protégé.app
PY        := .venv/bin/python

ONT := ontologi/$(GROUP)_M1P1_ontologi.owl
BAD := ontologi/$(GROUP)_M1P1_ontologi_inkonsisten.owl

.PHONY: all setup doctor check selftest reason reason-bad report package open clean

all: check

.venv:
	python3 -m venv .venv

setup: .venv
	$(PY) -m pip -q install --upgrade pip
	$(PY) -m pip -q install -r requirements.txt
	@echo "ok: venv siap ($(PY))"

doctor:
	@printf "%-12s" "java";       test -x "$(JAVA)" && "$(JAVA)" -version 2>&1 | head -1 || echo "MISSING -> lihat README"
	@printf "%-12s" "robot";      test -f "$(ROBOT)" && echo "$(ROBOT)" || echo "MISSING"
	@printf "%-12s" "protege";    test -d "$(PROTEGE)" && echo "$(PROTEGE)" || echo "MISSING"
	@printf "%-12s" "pdflatex";   command -v pdflatex >/dev/null && pdflatex --version | head -1 || echo "MISSING"
	@printf "%-12s" "venv";       test -x "$(PY)" && echo "$(PY)" || echo "belum: make setup"

check: setup
	@$(PY) tools/validate.py

selftest: setup
	@$(PY) tools/selftest.py

reason: setup
	@bash tools/reason.sh "$(ONT)" consistent

reason-bad: setup
	@bash tools/reason.sh "$(BAD)" inconsistent

report: setup
	@$(PY) tools/build_report.py

package: setup check
	@$(PY) tools/package.py

open:
	@test -d "$(PROTEGE)" && open -a "$(PROTEGE)" "$(ONT)" || echo "Protege tidak ada di $(PROTEGE)"

clean:
	rm -rf .venv __pycache__ tools/__pycache__ laporan/*.aux laporan/*.log laporan/*.out laporan/*.toc build
	find . -name '.DS_Store' -delete

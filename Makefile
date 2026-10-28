SHELL := /bin/bash

# --- resolusi tool -------------------------------------------------------
# Tidak ada path yang di-hardcode. Urutannya: variabel environment, lalu
# probing. Override kapan saja:  make doctor ROBOT=/path/robot.jar
#
# JAVA_HOME: registri macOS, lalu JDK lokal mana pun, lalu PATH.
JAVA_HOME ?= $(shell h=$$(/usr/libexec/java_home 2>/dev/null); \
                [ -n "$$h" ] || h=$$(ls -d $(HOME)/.hermes/tools/jdk/*/Contents/Home 2>/dev/null | head -1); \
                [ -n "$$h" ] || h=$$(dirname "$$(dirname "$$(command -v java 2>/dev/null)")" 2>/dev/null); \
                echo "$$h")
JAVA_BIN  := $(JAVA_HOME)/bin/java

# ROBOT: sembarang robot.jar di direktori tool, versi apa pun.
ROBOT     ?= $(firstword $(wildcard \
                $(HOME)/.hermes/tools/robot.jar \
                $(HOME)/.hermes/tools/*/robot.jar \
                $(HOME)/.local/share/robot.jar))

# Protege: bundle .app di /Applications atau di direktori tool.
PROTEGE   ?= $(firstword $(wildcard \
                /Applications/Protégé.app /Applications/Protege.app \
                $(HOME)/Applications/Protégé.app $(HOME)/Applications/Protege.app \
                $(HOME)/.hermes/tools/*/*/Protégé.app \
                $(HOME)/.hermes/tools/*/*/Protege.app))

PY        := .venv/bin/python

# Nomor kelompok dibaca dari config.yaml tanpa butuh pyyaml di python sistem.
GROUP := $(shell sed -n 's/^grup:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' config.yaml 2>/dev/null | head -1)

ONT := ontologi/$(GROUP)_M1P1_ontologi.owl
BAD := ontologi/$(GROUP)_M1P1_ontologi_inkonsisten.owl

.PHONY: all setup doctor check selftest reason reason-bad report package review open clean

all: check

.venv:
	python3 -m venv .venv

setup: .venv
	$(PY) -m pip -q install --upgrade pip
	$(PY) -m pip -q install -r requirements.txt
	@echo "ok: venv siap ($(PY))"

doctor:
	@printf "%-10s " "grup";      echo "$(GROUP) -> $(ONT)"
	@printf "%-10s " "java";      test -x "$(JAVA_BIN)" && "$(JAVA_BIN)" -version 2>&1 | head -1 || echo "MISSING, set JAVA_HOME=..."
	@printf "%-10s " "robot";     test -f "$(ROBOT)" && echo "$(ROBOT)" || echo "MISSING, set ROBOT=/path/robot.jar"
	@printf "%-10s " "protege";   test -d "$(PROTEGE)" && echo "$(PROTEGE)" || echo "MISSING, set PROTEGE=/path/Protege.app"
	@printf "%-10s " "pdflatex";  command -v pdflatex >/dev/null && pdflatex --version | head -1 || echo "MISSING"
	@printf "%-10s " "python";    test -x "$(PY)" && $(PY) --version || echo "belum: make setup"

check: setup
	@$(PY) tools/validate.py

selftest: setup
	@$(PY) tools/selftest.py

reason: setup
	@JAVA_BIN="$(JAVA_BIN)" ROBOT="$(ROBOT)" bash tools/reason.sh "$(ONT)" consistent

reason-bad: setup
	@JAVA_BIN="$(JAVA_BIN)" ROBOT="$(ROBOT)" bash tools/reason.sh "$(BAD)" inconsistent

report: setup
	@$(PY) tools/build_report.py

package: setup check
	@$(PY) tools/package.py

# Gerbang sebelum submit: check -> reason -> reason-bad -> report -> package.
# Berhenti di langkah pertama yang gagal.
review: setup
	@$(MAKE) --no-print-directory check
	@$(MAKE) --no-print-directory reason
	@$(MAKE) --no-print-directory reason-bad
	@$(MAKE) --no-print-directory report
	@$(MAKE) --no-print-directory package

open:
	@if [ -d "$(PROTEGE)" ]; then open -a "$(PROTEGE)" "$(ONT)"; \
	else echo "Protege tidak ketemu. Set PROTEGE=/path/Protege.app"; exit 1; fi

clean:
	rm -rf .venv __pycache__ tools/__pycache__ laporan/*.aux laporan/*.log laporan/*.out laporan/*.toc build
	find . -name '.DS_Store' -delete

SRCDIR   = src
BUILDDIR = build

APP_NAME = $(shell basename $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
APP_CR   = $(shell find $(SRCDIR) -name "*.cr")
APP_MAIN = $(SRCDIR)/$(APP_NAME).cr
APP_EXE  = $(BUILDDIR)/$(APP_NAME)

.PHONY: all build

all: build

build: $(APP_EXE)

$(APP_EXE): $(APP_CR) | $(BUILDDIR)/
	crystal build -o $@ $(APP_MAIN)

$(BUILDDIR)/:
	mkdir -p $@


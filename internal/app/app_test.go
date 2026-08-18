package app

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Elliot-Wang/unix-config-sync/internal/config"
)

func TestFindSourceDir(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, ".chezmoiroot"), []byte("home\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, ".unix-sync.json"), []byte("{}\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	nested := filepath.Join(root, "one", "two")
	if err := os.MkdirAll(nested, 0o700); err != nil {
		t.Fatal(err)
	}
	got, err := FindSourceDir(nested)
	if err != nil {
		t.Fatal(err)
	}
	if got != root {
		t.Fatalf("FindSourceDir() = %q, want %q", got, root)
	}
}

func TestRunNonInteractiveInit(t *testing.T) {
	root := t.TempDir()
	manifestJSON := `{
  "schemaVersion": 1,
  "applications": [{"id":"git","label":"Git","required":true,"packages":{"darwin":"git"}}],
  "profiles": [{"id":"personal","label":"Personal","shellMode":"modern","applications":[]}]
}`
	if err := os.WriteFile(filepath.Join(root, ".chezmoiroot"), []byte("home\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, ".unix-sync.json"), []byte(manifestJSON), 0o600); err != nil {
		t.Fatal(err)
	}
	configPath := filepath.Join(t.TempDir(), "chezmoi.json")
	t.Setenv("CONFIG_SYNC_CONFIG", configPath)
	var stdout, stderr bytes.Buffer
	err := Run(
		[]string{"init", "--source", root, "--profile", "personal", "--non-interactive"},
		strings.NewReader(""), &stdout, &stderr,
	)
	if err != nil {
		t.Fatalf("Run() error = %v, stderr = %s", err, stderr.String())
	}
	value, err := config.Load(configPath)
	if err != nil {
		t.Fatal(err)
	}
	if value.SourceDir != root || value.Data.Profile != "personal" || value.Data.ShellMode != "modern" || !value.Data.Applications["git"] {
		t.Fatalf("unexpected saved config: %#v", value)
	}
	if !strings.Contains(stdout.String(), "Saved machine settings") {
		t.Fatalf("unexpected output: %s", stdout.String())
	}
}

func TestSyncDryRunDoesNotInitializeMachine(t *testing.T) {
	root := t.TempDir()
	manifestJSON := `{
  "schemaVersion": 1,
  "applications": [{"id":"git","label":"Git","required":true,"packages":{"darwin":"git"}}],
  "profiles": [{"id":"personal","label":"Personal","shellMode":"modern","applications":[]}]
}`
	if err := os.WriteFile(filepath.Join(root, ".chezmoiroot"), []byte("home\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, ".unix-sync.json"), []byte(manifestJSON), 0o600); err != nil {
		t.Fatal(err)
	}
	configPath := filepath.Join(t.TempDir(), "does-not-exist", "chezmoi.json")
	t.Setenv("CONFIG_SYNC_CONFIG", configPath)
	var stdout, stderr bytes.Buffer
	err := Run(
		[]string{"sync", "--dry-run", "--source", root},
		strings.NewReader(""), &stdout, &stderr,
	)
	if err != nil {
		t.Fatalf("Run() error = %v, stderr = %s", err, stderr.String())
	}
	if !strings.Contains(stdout.String(), "READ-ONLY DRY RUN") || !strings.Contains(stdout.String(), "no initialization was performed") {
		t.Fatalf("unexpected output: %s", stdout.String())
	}
	if _, err := os.Stat(configPath); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("dry run created persistent config: %v", err)
	}
}

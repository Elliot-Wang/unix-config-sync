package lifecycle

import (
	"slices"
	"testing"

	"github.com/Elliot-Wang/unix-config-sync/internal/config"
	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
)

func lifecycleFixture() (config.Config, manifest.Manifest, platform.Info) {
	definitions := manifest.Manifest{Applications: []manifest.Application{
		{ID: "eza", Label: "eza", Packages: map[string]string{"darwin": "eza", "debian": "eza"}, ConfigPaths: []string{".config/eza/**"}},
	}}
	value := config.Config{Data: config.MachineData{Applications: map[string]bool{"eza": true}, Versions: map[string]string{}}}
	return value, definitions, platform.Info{OS: "darwin", OSID: "darwin"}
}

func TestResolveDisabledInstalledApplicationRemovesPackageAndStopsConfig(t *testing.T) {
	value, definitions, info := lifecycleFixture()
	value.Data.Applications["eza"] = false
	items := Resolve(value, definitions, info, map[string]Fact{"eza": {Installed: "0.23.0"}})
	if len(items) != 1 || items[0].Action != Remove || items[0].Detail != "disabled; config sync is off" {
		t.Fatalf("unexpected lifecycle item: %#v", items)
	}
}

func TestHomebrewExactAvailableVersionInstallsThenPins(t *testing.T) {
	value, definitions, info := lifecycleFixture()
	value.SetVersion("eza", "0.23.5")
	facts := map[string]Fact{"eza": {Available: "0.23.5"}}
	items := Resolve(value, definitions, info, facts)
	if items[0].Action != Install {
		t.Fatalf("action = %s, want INSTALL", items[0].Action)
	}
	operations, err := Operations(ModeReconcile, value, definitions, info, facts)
	if err != nil {
		t.Fatal(err)
	}
	if len(operations) != 2 || !slices.Equal(operations[0].Args, []string{"install", "eza"}) || !slices.Equal(operations[1].Args, []string{"pin", "eza"}) {
		t.Fatalf("unexpected Homebrew operations: %#v", operations)
	}
}

func TestHomebrewHistoricalVersionIsUnsupported(t *testing.T) {
	value, definitions, info := lifecycleFixture()
	value.SetVersion("eza", "0.18.0")
	facts := map[string]Fact{"eza": {Installed: "0.23.0", Available: "0.23.5"}}
	items := Resolve(value, definitions, info, facts)
	if items[0].Action != Unsupported {
		t.Fatalf("action = %s, want UNSUPPORTED", items[0].Action)
	}
	if _, err := Operations(ModeReconcile, value, definitions, info, facts); err == nil {
		t.Fatal("expected reconcile to reject an unavailable Homebrew version")
	}
}

func TestDebianExactVersionUsesNativePackageSyntax(t *testing.T) {
	value, definitions, _ := lifecycleFixture()
	value.SetVersion("eza", "1.2.3-1")
	info := platform.Info{OS: "linux", OSID: "linux-debian"}
	facts := map[string]Fact{"eza": {Installed: "1.2.2-1", Available: "1.2.3-1"}}
	operations, err := Operations(ModeReconcile, value, definitions, info, facts)
	if err != nil {
		t.Fatal(err)
	}
	if len(operations) != 1 || !slices.Equal(operations[0].Args[len(operations[0].Args)-4:], []string{"install", "-y", "--allow-downgrades", "eza=1.2.3-1"}) {
		t.Fatalf("unexpected apt operation: %#v", operations)
	}
}

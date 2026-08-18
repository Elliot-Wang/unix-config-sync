package manifest

import "testing"

func validManifest() Manifest {
	return Manifest{
		SchemaVersion: 1,
		Applications: []Application{{
			ID: "git", Label: "Git", Packages: map[string]string{"darwin": "git", "windows": "Git.Git"},
		}},
		Profiles: []Profile{{
			ID: "personal", Label: "Personal", ShellMode: ShellModern, Applications: []string{"git"},
		}},
	}
}

func TestValidate(t *testing.T) {
	if err := validManifest().Validate(); err != nil {
		t.Fatal(err)
	}
	value := validManifest()
	value.Profiles[0].Applications = append(value.Profiles[0].Applications, "missing")
	if err := value.Validate(); err == nil {
		t.Fatal("expected an unknown application error")
	}
}

func TestApplicationSupportsAndPackage(t *testing.T) {
	application := Application{Packages: map[string]string{"darwin": "git", "rhel": "git-core"}}
	if !application.Supports("linux-centos", "rhel") {
		t.Fatal("expected rhel family support")
	}
	if application.Supports("windows", "windows") {
		t.Fatal("did not expect windows support")
	}
	if name, ok := application.Package("linux-centos", "rhel"); !ok || name != "git-core" {
		t.Fatalf("Package() = %q, %v", name, ok)
	}
}

func TestValidateRejectsConfigPathOutsideHome(t *testing.T) {
	value := validManifest()
	value.Applications[0].ConfigPaths = []string{"../private"}
	if err := value.Validate(); err == nil {
		t.Fatal("expected unsafe config path error")
	}
}

package platform

import (
	"os"
	"path/filepath"
	"testing"
)

func TestReadOSRelease(t *testing.T) {
	path := filepath.Join(t.TempDir(), "os-release")
	content := "# comment\nID=centos\nVERSION_ID=\"9\"\nNAME='CentOS Stream'\n"
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	got, err := ReadOSRelease(path)
	if err != nil {
		t.Fatal(err)
	}
	if got["ID"] != "centos" || got["VERSION_ID"] != "9" || got["NAME"] != "CentOS Stream" {
		t.Fatalf("unexpected os-release values: %#v", got)
	}
}

func TestFamily(t *testing.T) {
	tests := map[string]string{
		"linux-centos": "rhel",
		"linux-rocky":  "rhel",
		"linux-ubuntu": "debian",
		"darwin":       "darwin",
		"windows":      "windows",
	}
	for osID, want := range tests {
		if got := (Info{OS: osID, OSID: osID}).Family(); got != want {
			t.Errorf("Family(%q) = %q, want %q", osID, got, want)
		}
	}
}

func TestRHELPackageManager(t *testing.T) {
	tests := []struct {
		version string
		want    string
	}{
		{version: "7.9", want: "yum"},
		{version: "8.10", want: "dnf"},
		{version: "9", want: "dnf"},
	}
	for _, test := range tests {
		info := Info{OS: "linux", OSID: "linux-centos", OSVersion: test.version}
		if got := info.PackageManager(); got != test.want {
			t.Errorf("PackageManager(version=%q) = %q, want %q", test.version, got, test.want)
		}
	}
}

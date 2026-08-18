package manifest

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
)

const Filename = ".unix-sync.json"

const (
	ShellLegacy = "legacy"
	ShellModern = "modern"
)

type Manifest struct {
	SchemaVersion int           `json:"schemaVersion"`
	Applications  []Application `json:"applications"`
	Profiles      []Profile     `json:"profiles"`
}

// Application is the unit selected by users. Package names are resolved by
// platform family and delivered by that platform's native package manager.
type Application struct {
	ID          string            `json:"id"`
	Label       string            `json:"label"`
	Description string            `json:"description"`
	Kind        string            `json:"kind,omitempty"`
	Required    bool              `json:"required,omitempty"`
	Packages    map[string]string `json:"packages"`
	ConfigPaths []string          `json:"configPaths,omitempty"`
}

type Profile struct {
	ID           string   `json:"id"`
	Label        string   `json:"label"`
	Description  string   `json:"description"`
	ShellMode    string   `json:"shellMode"`
	Applications []string `json:"applications"`
}

func Load(sourceDir string) (Manifest, error) {
	path := filepath.Join(sourceDir, Filename)
	data, err := os.ReadFile(path)
	if err != nil {
		return Manifest{}, err
	}
	var value Manifest
	if err := json.Unmarshal(data, &value); err != nil {
		return Manifest{}, fmt.Errorf("parse %s: %w", path, err)
	}
	if err := value.Validate(); err != nil {
		return Manifest{}, fmt.Errorf("validate %s: %w", path, err)
	}
	return value, nil
}

func (m Manifest) Validate() error {
	if m.SchemaVersion != 1 {
		return fmt.Errorf("unsupported schemaVersion %d", m.SchemaVersion)
	}
	if len(m.Applications) == 0 || len(m.Profiles) == 0 {
		return errors.New("applications and profiles must not be empty")
	}
	applicationIDs := make(map[string]struct{}, len(m.Applications))
	for _, application := range m.Applications {
		if application.ID == "" || application.Label == "" {
			return errors.New("every application needs an id and label")
		}
		if len(application.Packages) == 0 {
			return fmt.Errorf("application %q needs at least one platform package", application.ID)
		}
		if application.Kind != "" && application.Kind != "desktop" && application.Kind != "bootstrap" {
			return fmt.Errorf("application %q has unknown kind %q", application.ID, application.Kind)
		}
		for _, path := range application.ConfigPaths {
			if path == "" || filepath.IsAbs(path) || path == "." || strings.HasPrefix(filepath.Clean(path), "..") {
				return fmt.Errorf("application %q has unsafe config path %q", application.ID, path)
			}
		}
		if _, exists := applicationIDs[application.ID]; exists {
			return fmt.Errorf("duplicate application %q", application.ID)
		}
		applicationIDs[application.ID] = struct{}{}
	}
	profileIDs := make(map[string]struct{}, len(m.Profiles))
	for _, profile := range m.Profiles {
		if profile.ID == "" || profile.Label == "" {
			return errors.New("every profile needs an id and label")
		}
		if !ValidShellMode(profile.ShellMode) {
			return fmt.Errorf("profile %q has unknown shellMode %q", profile.ID, profile.ShellMode)
		}
		if _, exists := profileIDs[profile.ID]; exists {
			return fmt.Errorf("duplicate profile %q", profile.ID)
		}
		profileIDs[profile.ID] = struct{}{}
		seenApplications := make(map[string]struct{}, len(profile.Applications))
		for _, applicationID := range profile.Applications {
			if _, exists := applicationIDs[applicationID]; !exists {
				return fmt.Errorf("profile %q references unknown application %q", profile.ID, applicationID)
			}
			if _, exists := seenApplications[applicationID]; exists {
				return fmt.Errorf("profile %q repeats application %q", profile.ID, applicationID)
			}
			seenApplications[applicationID] = struct{}{}
		}
	}
	return nil
}

func (m Manifest) Profile(id string) (Profile, bool) {
	for _, profile := range m.Profiles {
		if profile.ID == id {
			return profile, true
		}
	}
	return Profile{}, false
}

func (m Manifest) Application(id string) (Application, bool) {
	for _, application := range m.Applications {
		if application.ID == id {
			return application, true
		}
	}
	return Application{}, false
}

func (a Application) Supports(osID, family string) bool {
	_, exact := a.Packages[osID]
	_, grouped := a.Packages[family]
	return exact || grouped
}

func (a Application) Package(osID, family string) (string, bool) {
	if value, ok := a.Packages[osID]; ok {
		return value, true
	}
	value, ok := a.Packages[family]
	return value, ok
}

func (p Profile) Includes(applicationID string) bool {
	return slices.Contains(p.Applications, applicationID)
}

func ValidShellMode(value string) bool {
	return value == ShellLegacy || value == ShellModern
}

var versionPattern = regexp.MustCompile(`^[0-9A-Za-z][0-9A-Za-z.+:~_-]*$`)

// ValidVersion accepts exact native package versions without allowing shell
// metacharacters into generated package-manager scripts. "latest" is the
// portable rolling policy and is not persisted as an exact version.
func ValidVersion(value string) bool {
	return value == "" || value == "latest" || versionPattern.MatchString(value)
}

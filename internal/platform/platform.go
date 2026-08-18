package platform

import (
	"bufio"
	"os"
	"runtime"
	"strings"
)

// Info describes the machine facts used to resolve profiles and templates.
type Info struct {
	OS        string `json:"os"`
	OSID      string `json:"osid"`
	Arch      string `json:"arch"`
	Hostname  string `json:"hostname"`
	HomeDir   string `json:"homeDir"`
	OSVersion string `json:"osVersion,omitempty"`
}

// Detect returns platform facts without mutating the machine.
func Detect() Info {
	hostname, _ := os.Hostname()
	home, _ := os.UserHomeDir()
	info := Info{
		OS:       runtime.GOOS,
		OSID:     runtime.GOOS,
		Arch:     runtime.GOARCH,
		Hostname: shortHostname(hostname),
		HomeDir:  home,
	}
	if runtime.GOOS == "linux" {
		values, err := ReadOSRelease("/etc/os-release")
		if err == nil {
			if id := values["ID"]; id != "" {
				info.OSID = "linux-" + strings.ToLower(id)
			}
			info.OSVersion = values["VERSION_ID"]
		}
	}
	return info
}

// ReadOSRelease parses the simple KEY=VALUE format used by /etc/os-release.
func ReadOSRelease(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	values := make(map[string]string)
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		values[strings.TrimSpace(key)] = strings.Trim(strings.TrimSpace(value), `"'`)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return values, nil
}

func shortHostname(hostname string) string {
	if name, _, ok := strings.Cut(hostname, "."); ok {
		return name
	}
	return hostname
}

// Family normalizes RHEL-compatible distributions for package planning.
func (i Info) Family() string {
	switch i.OSID {
	case "linux-centos", "linux-rhel", "linux-rocky", "linux-almalinux", "linux-fedora":
		return "rhel"
	case "linux-debian", "linux-ubuntu":
		return "debian"
	default:
		return i.OS
	}
}

func (i Info) PackageManager() string {
	switch i.Family() {
	case "darwin":
		return "brew"
	case "windows":
		return "winget"
	case "rhel":
		if strings.HasPrefix(i.OSVersion, "7") {
			return "yum"
		}
		return "dnf"
	case "debian":
		return "apt-get"
	default:
		return ""
	}
}

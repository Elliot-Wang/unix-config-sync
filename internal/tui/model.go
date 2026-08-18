package tui

import (
	"encoding/json"
	"fmt"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/charmbracelet/x/ansi"

	"github.com/Elliot-Wang/unix-config-sync/internal/config"
	"github.com/Elliot-Wang/unix-config-sync/internal/lifecycle"
	"github.com/Elliot-Wang/unix-config-sync/internal/manifest"
	"github.com/Elliot-Wang/unix-config-sync/internal/plan"
	"github.com/Elliot-Wang/unix-config-sync/internal/platform"
)

type Result struct {
	Config   config.Config
	Action   lifecycle.Mode
	Canceled bool
}

type choice struct {
	id          string
	label       string
	description string
	available   bool
	required    bool
	kind        string
}

type Model struct {
	config      config.Config
	definitions manifest.Manifest
	platform    platform.Info
	choices     []choice
	cursor      int
	preview     int
	scroll      int
	width       int
	height      int
	finished    bool
	canceled    bool
	facts       map[string]lifecycle.Fact
	action      lifecycle.Mode
	confirming  lifecycle.Mode
	versionEdit bool
	versionText string
	versionErr  string
}

var (
	titleStyle   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("12"))
	sectionStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("14"))
	activeStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("15")).Background(lipgloss.Color("24"))
	mutedStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	applyStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("10"))
	ignoreStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
)

func New(value config.Config, definitions manifest.Manifest, info platform.Info, factSets ...map[string]lifecycle.Fact) *Model {
	facts := make(map[string]lifecycle.Fact)
	if len(factSets) > 0 && factSets[0] != nil {
		facts = factSets[0]
	}
	m := &Model{
		config:      value,
		definitions: definitions,
		platform:    info,
		width:       80,
		height:      24,
		facts:       facts,
	}
	m.rebuildChoices()
	if len(m.choices) > 0 && !m.choices[m.cursor].available {
		m.move(1)
	}
	return m
}

func Run(value config.Config, definitions manifest.Manifest, info platform.Info, facts map[string]lifecycle.Fact) (Result, error) {
	program := tea.NewProgram(New(value, definitions, info, facts))
	final, err := program.Run()
	if err != nil {
		return Result{}, err
	}
	model, ok := final.(*Model)
	if !ok {
		return Result{}, fmt.Errorf("unexpected TUI model %T", final)
	}
	return model.Result(), nil
}

func (m *Model) Result() Result {
	return Result{Config: m.config, Action: m.action, Canceled: m.canceled || !m.finished}
}

func (m *Model) Init() tea.Cmd {
	return tea.RequestWindowSize
}

func (m *Model) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	case tea.KeyPressMsg:
		if m.versionEdit {
			m.updateVersion(msg)
			return m, nil
		}
		if m.confirming != "" {
			switch msg.String() {
			case "y", "Y":
				m.action = m.confirming
				m.finished = true
				return m, tea.Quit
			case "n", "N", "esc", "q":
				m.confirming = ""
			}
			return m, nil
		}
		switch msg.String() {
		case "ctrl+c", "q", "esc":
			m.canceled = true
			return m, tea.Quit
		case "up", "k":
			m.navigate(-1)
		case "down", "j":
			m.navigate(1)
		case "pgup", "ctrl+b":
			m.navigate(-m.pageSize())
		case "pgdown", "ctrl+f":
			m.navigate(m.pageSize())
		case "home", "g":
			m.toBoundary(false)
		case "end", "G":
			m.toBoundary(true)
		case "space":
			if m.preview == 0 {
				m.toggleCurrent()
			}
		case "p":
			m.nextProfile()
		case "v":
			m.beginVersionEdit()
		case "i":
			m.preview = 1
			m.scroll = 0
			m.confirming = lifecycle.ModeReconcile
		case "u":
			m.preview = 1
			m.scroll = 0
			m.confirming = lifecycle.ModeUpgrade
		case "x":
			m.preview = 1
			m.scroll = 0
			m.confirming = lifecycle.ModeRemove
		case "tab":
			m.preview = (m.preview + 1) % 3
			m.scroll = 0
		case "shift+tab":
			m.preview = (m.preview + 2) % 3
			m.scroll = 0
		case "1", "2", "3":
			m.preview = int(msg.String()[0] - '1')
			m.scroll = 0
		case "enter":
			m.finished = true
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m *Model) View() tea.View {
	content := m.render()
	view := tea.NewView(content)
	view.AltScreen = true
	view.WindowTitle = "unix-sync settings"
	return view
}

func (m *Model) rebuildChoices() {
	m.choices = m.choices[:0]
	for _, application := range m.definitions.Applications {
		m.choices = append(m.choices, choice{
			id: application.ID, label: application.Label,
			description: application.Description,
			available:   application.Supports(m.platform.OSID, m.platform.Family()),
			required:    application.Required,
			kind:        application.Kind,
		})
	}
	if m.cursor >= len(m.choices) {
		m.cursor = len(m.choices) - 1
	}
}

func (m *Model) move(delta int) {
	if len(m.choices) == 0 {
		return
	}
	for attempts := 0; attempts < len(m.choices); attempts++ {
		m.cursor = (m.cursor + delta + len(m.choices)) % len(m.choices)
		if m.choices[m.cursor].available {
			return
		}
	}
}

func (m *Model) toggleCurrent() {
	if len(m.choices) == 0 || !m.choices[m.cursor].available || m.choices[m.cursor].required {
		return
	}
	current := m.choices[m.cursor]
	m.config.Data.Applications[current.id] = !m.config.Data.Applications[current.id]
	config.RefreshManifestData(&m.config, m.definitions)
}

func (m *Model) beginVersionEdit() {
	if m.preview != 0 || len(m.choices) == 0 {
		return
	}
	current := m.choices[m.cursor]
	if !current.available || current.kind == "bootstrap" || !m.config.Data.Applications[current.id] {
		return
	}
	m.versionEdit = true
	m.versionText = m.config.Version(current.id)
	m.versionErr = ""
}

func (m *Model) updateVersion(msg tea.KeyPressMsg) {
	switch msg.String() {
	case "esc":
		m.versionEdit = false
		m.versionErr = ""
	case "enter":
		value := strings.TrimSpace(m.versionText)
		if !manifest.ValidVersion(value) {
			m.versionErr = "use latest or an exact version containing letters, digits, . + : ~ _ -"
			return
		}
		m.config.SetVersion(m.choices[m.cursor].id, value)
		config.RefreshManifestData(&m.config, m.definitions)
		m.versionEdit = false
		m.versionErr = ""
	case "backspace":
		if len(m.versionText) > 0 {
			runes := []rune(m.versionText)
			m.versionText = string(runes[:len(runes)-1])
		}
	case "ctrl+u":
		m.versionText = ""
	default:
		if msg.Key().Text != "" {
			m.versionText += msg.Key().Text
		}
	}
}

func (m *Model) navigate(delta int) {
	if m.preview == 0 {
		steps := delta
		direction := 1
		if delta < 0 {
			direction = -1
			steps = -delta
		}
		steps = max(1, steps)
		for range steps {
			m.move(direction)
		}
		return
	}
	m.scroll = min(max(0, m.scroll+delta), m.maxScroll())
}

func (m *Model) toBoundary(end bool) {
	if m.preview == 0 {
		if len(m.choices) == 0 {
			return
		}
		m.cursor = 0
		if end {
			m.cursor = len(m.choices) - 1
		}
		if !m.choices[m.cursor].available {
			direction := 1
			if end {
				direction = -1
			}
			m.move(direction)
		}
		return
	}
	if end {
		m.scroll = m.maxScroll()
	} else {
		m.scroll = 0
	}
}

func (m *Model) nextProfile() {
	if len(m.definitions.Profiles) == 0 {
		return
	}
	index := 0
	for i, profile := range m.definitions.Profiles {
		if profile.ID == m.config.Data.Profile {
			index = (i + 1) % len(m.definitions.Profiles)
			break
		}
	}
	config.ApplyProfile(&m.config, m.definitions.Profiles[index], m.definitions, m.platform)
}

func (m *Model) render() string {
	width := m.width
	if width < 50 {
		width = 50
	}
	if width > 110 {
		width = 110
	}
	var out strings.Builder
	line := strings.Repeat("─", max(1, width-21))
	fmt.Fprintf(&out, "%s\n", titleStyle.Render(" UNIX-SYNC ")+mutedStyle.Render(" settings ")+mutedStyle.Render(line))
	fmt.Fprintf(&out, "%s  %s  %s/%s  profile=%s  shell=%s\n\n",
		mutedStyle.Render("machine"), m.config.Data.Machine,
		m.platform.OSID, m.platform.Arch, sectionStyle.Render(m.config.Data.Profile), sectionStyle.Render(m.config.Data.ShellMode))

	labels := []string{"applications", "plan", "profile"}
	for index, label := range labels {
		if index == m.preview {
			out.WriteString(titleStyle.Render(fmt.Sprintf("[%d] %s", index+1, label)) + "  ")
		} else {
			out.WriteString(mutedStyle.Render(fmt.Sprintf("[%d] %s", index+1, label)) + "  ")
		}
	}
	out.WriteString("\n" + strings.Repeat("─", width-2) + "\n")
	m.renderContent(&out)
	if m.versionEdit {
		out.WriteString("\n" + sectionStyle.Render("Desired version") + "  " + m.versionText + "▏\n")
		if m.versionErr != "" {
			out.WriteString(ignoreStyle.Render(m.versionErr) + "\n")
		}
		out.WriteString(mutedStyle.Render("enter accept  esc cancel  ctrl+u clear"))
	} else if m.confirming != "" {
		out.WriteString("\n" + sectionStyle.Render("CONFIRM "+strings.ToUpper(string(m.confirming))) + "\n")
		out.WriteString(m.confirmationText() + "\n")
		out.WriteString(mutedStyle.Render("y execute reviewed operations  esc return to plan"))
	} else {
		out.WriteString("\n" + mutedStyle.Render("tab view  ↑/↓ navigate  space optional app  v version  p profile") + "\n")
		out.WriteString(mutedStyle.Render("i reconcile  u upgrade latest  x remove disabled  enter save only  q cancel"))
	}
	return out.String()
}

func (m *Model) marker(item choice) string {
	if !item.available {
		return "[-]"
	}
	if item.required {
		return "[*]"
	}
	if m.config.Data.Applications[item.id] {
		return "[x]"
	}
	return "[ ]"
}

func (m *Model) renderContent(out *strings.Builder) {
	switch m.preview {
	case 0:
		m.renderApplications(out)
	case 1:
		items := plan.ResolveConfig(m.config, m.platform)
		lines := make([]string, 0, len(items)+len(m.choices))
		for _, item := range items {
			style := applyStyle
			switch item.Action {
			case plan.Ignore:
				style = ignoreStyle
			}
			line := fmt.Sprintf("  %s  %-24s", style.Render(fmt.Sprintf("%-7s", item.Action)), item.Target)
			if item.Detail != "" {
				line += " " + mutedStyle.Render(item.Detail)
			}
			lines = append(lines, line)
		}
		for _, item := range lifecycle.Resolve(m.config, m.definitions, m.platform, m.facts) {
			style := applyStyle
			if item.Action == lifecycle.Ignore || item.Action == lifecycle.Keep {
				style = ignoreStyle
			}
			desired := item.Desired
			installed := item.Installed
			if installed == "" {
				installed = "missing"
			}
			line := fmt.Sprintf("  %s  %-18s desired=%-10s installed=%s", style.Render(fmt.Sprintf("%-11s", item.Action)), item.Label, desired, installed)
			if item.Available != "" && item.Available != item.Installed {
				line += " available=" + item.Available
			}
			lines = append(lines, line)
		}
		out.WriteString(renderViewport(lines, m.scroll, m.pageSize(), m.contentWidth()))
	case 2:
		data, _ := json.MarshalIndent(m.config.Data, "", "  ")
		lines := strings.Split(string(data), "\n")
		for index := range lines {
			lines[index] = "  " + lines[index]
		}
		out.WriteString(renderViewport(lines, m.scroll, m.pageSize(), m.contentWidth()))
	}
}

func (m *Model) renderApplications(out *strings.Builder) {
	limit := m.pageSize()
	visibleCount := min(limit, len(m.choices))
	if len(m.choices) > limit {
		visibleCount = max(1, limit-1)
	}
	start := max(0, m.cursor-visibleCount/2)
	start = min(start, max(0, len(m.choices)-visibleCount))
	end := start + visibleCount
	for index := start; index < end; index++ {
		item := m.choices[index]
		prefix := "  "
		if index == m.cursor {
			prefix = "> "
		}
		desired := m.config.Version(item.id)
		installed := m.facts[item.id].Installed
		if installed == "" {
			installed = "missing"
		}
		row := fmt.Sprintf("%s%s %-16s %-10s %-12s -- %s", prefix, m.marker(item), item.label, desired, installed, item.description)
		if !item.available {
			row += " " + mutedStyle.Render("not available on "+m.platform.OSID)
		} else if item.required {
			row += " " + sectionStyle.Render("required")
		}
		row = ansi.Truncate(row, m.contentWidth(), "…")
		if index == m.cursor {
			row = activeStyle.Render(row)
		}
		out.WriteString(row + "\n")
	}
	if start > 0 || end < len(m.choices) {
		fmt.Fprintf(out, "  %s\n", mutedStyle.Render(fmt.Sprintf("applications %d-%d/%d", start+1, end, len(m.choices))))
	}
}

func (m *Model) contentWidth() int {
	return min(max(m.width, 50), 110) - 2
}

func (m *Model) pageSize() int {
	return max(5, m.height-9)
}

func (m *Model) contentLineCount() int {
	switch m.preview {
	case 1:
		return len(plan.ResolveConfig(m.config, m.platform)) + len(lifecycle.Resolve(m.config, m.definitions, m.platform, m.facts))
	case 2:
		data, _ := json.MarshalIndent(m.config.Data, "", "  ")
		return len(strings.Split(string(data), "\n"))
	default:
		return len(m.choices)
	}
}

func (m *Model) confirmationText() string {
	switch m.confirming {
	case lifecycle.ModeReconcile:
		return "Install missing applications and converge exact versions. Disabled applications are not removed."
	case lifecycle.ModeUpgrade:
		return "Upgrade selected applications whose desired version is latest. Exact-version applications stay pinned."
	case lifecycle.ModeRemove:
		return "Uninstall disabled catalog applications. Their config paths are already excluded from synchronization; local config files are preserved."
	default:
		return ""
	}
}

func (m *Model) maxScroll() int {
	return max(0, m.contentLineCount()-m.pageSize()+1)
}

func renderViewport(lines []string, start, limit, width int) string {
	if len(lines) == 0 {
		return mutedStyle.Render("  Nothing to show.") + "\n"
	}
	start = min(max(0, start), max(0, len(lines)-limit+1))
	contentLimit := limit
	if len(lines) > limit {
		contentLimit--
	}
	end := min(len(lines), start+max(1, contentLimit))
	visible := append([]string(nil), lines[start:end]...)
	for index := range visible {
		visible[index] = ansi.Truncate(visible[index], width, "…")
	}
	if len(lines) > limit {
		visible = append(visible, mutedStyle.Render(fmt.Sprintf("  lines %d-%d/%d", start+1, end, len(lines))))
	}
	return strings.Join(visible, "\n") + "\n"
}

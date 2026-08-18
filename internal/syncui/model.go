package syncui

import (
	"fmt"
	"strings"
	"unicode/utf8"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
)

type Action string

const (
	ActionNone     Action = ""
	ActionApply    Action = "apply"
	ActionCapture  Action = "capture"
	ActionUpdate   Action = "update"
	ActionSettings Action = "settings"
	ActionRefresh  Action = "refresh"
)

type Snapshot struct {
	Machine       string
	OSID          string
	Arch          string
	Profile       string
	ShellMode     string
	SourceDir     string
	ManagedStatus string
	Diff          string
	RepoStatus    string
	Ephemeral     bool
	BackendError  string
	Notice        string
}

type Result struct {
	Action   Action
	Canceled bool
}

type Model struct {
	snapshot   Snapshot
	tab        int
	width      int
	height     int
	scroll     int
	confirming Action
	result     Result
}

var (
	titleStyle   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("12"))
	sectionStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("14"))
	mutedStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	safeStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("10"))
	warnStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("11"))
	errorStyle   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("9"))
)

func New(snapshot Snapshot) *Model {
	return &Model{snapshot: snapshot, width: 90, height: 28}
}

func Run(snapshot Snapshot) (Result, error) {
	program := tea.NewProgram(New(snapshot))
	final, err := program.Run()
	if err != nil {
		return Result{}, err
	}
	model, ok := final.(*Model)
	if !ok {
		return Result{}, fmt.Errorf("unexpected sync TUI model %T", final)
	}
	return model.result, nil
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
		key := msg.String()
		if m.confirming != ActionNone {
			switch key {
			case "y", "Y":
				m.result.Action = m.confirming
				return m, tea.Quit
			case "n", "N", "esc", "q":
				m.confirming = ActionNone
			}
			return m, nil
		}
		switch key {
		case "ctrl+c", "q", "esc":
			m.result.Canceled = true
			return m, tea.Quit
		case "tab", "right", "l":
			m.tab = (m.tab + 1) % 3
			m.scroll = 0
		case "shift+tab", "left", "h":
			m.tab = (m.tab + 2) % 3
			m.scroll = 0
		case "1", "2", "3":
			m.tab = int(key[0] - '1')
			m.scroll = 0
		case "down", "j":
			m.move(1)
		case "up", "k":
			m.move(-1)
		case "pgdown", "ctrl+f":
			m.move(m.pageSize())
		case "pgup", "ctrl+b":
			m.move(-m.pageSize())
		case "home", "g":
			m.scroll = 0
		case "end", "G":
			m.scroll = m.maxScroll()
		case "a":
			m.request(ActionApply)
		case "c":
			m.request(ActionCapture)
		case "u":
			m.request(ActionUpdate)
		case "s":
			m.result.Action = ActionSettings
			return m, tea.Quit
		case "r":
			m.result.Action = ActionRefresh
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m *Model) View() tea.View {
	view := tea.NewView(m.render())
	view.AltScreen = true
	view.WindowTitle = "unix-sync"
	return view
}

func (m *Model) request(action Action) {
	if m.snapshot.BackendError == "" {
		m.confirming = action
	}
}

func (m *Model) render() string {
	width := min(max(m.width, 60), 120)
	var out strings.Builder
	line := strings.Repeat("─", max(1, width-28))
	fmt.Fprintf(&out, "%s\n", titleStyle.Render(" UNIX-SYNC ")+mutedStyle.Render(" sync ")+mutedStyle.Render(line))
	fmt.Fprintf(&out, "%s  %s/%s  profile=%s  shell=%s  %s\n",
		m.snapshot.Machine, m.snapshot.OSID, m.snapshot.Arch,
		sectionStyle.Render(m.snapshot.Profile), sectionStyle.Render(m.snapshot.ShellMode), safeStyle.Render("READ-ONLY PREVIEW"))
	configMode := "saved machine profile"
	if m.snapshot.Ephemeral {
		configMode = "temporary defaults (nothing initialized)"
	}
	fmt.Fprintf(&out, "%s %s\n%s %s\n\n",
		mutedStyle.Render("source"), m.snapshot.SourceDir,
		mutedStyle.Render("mode  "), configMode)
	if m.snapshot.Notice != "" {
		out.WriteString(safeStyle.Render("✓ "+m.snapshot.Notice) + "\n\n")
	}

	labels := []string{"STATUS", "DIFF", "REPOSITORY"}
	for index, label := range labels {
		text := fmt.Sprintf("[%d] %s", index+1, label)
		if index == m.tab {
			out.WriteString(titleStyle.Render(text))
		} else {
			out.WriteString(mutedStyle.Render(text))
		}
		out.WriteString("   ")
	}
	out.WriteString("\n" + strings.Repeat("─", width-2) + "\n")

	if m.snapshot.BackendError != "" {
		out.WriteString(errorStyle.Render("Preview unavailable: "+m.snapshot.BackendError) + "\n")
		out.WriteString(mutedStyle.Render("Install chezmoi or press s to inspect machine settings.") + "\n")
	} else {
		content := m.tabContent()
		out.WriteString(viewport(content, m.scroll, m.pageSize(), width-2))
	}

	if m.confirming != ActionNone {
		out.WriteString("\n" + warnStyle.Render("CONFIRM "+strings.ToUpper(string(m.confirming))) + "\n")
		out.WriteString(m.confirmationText() + "\n")
		out.WriteString(warnStyle.Render("Press y to continue; Esc returns to the preview."))
	} else {
		out.WriteString("\n" + sectionStyle.Render("Actions") + "\n")
		if m.snapshot.BackendError == "" {
			out.WriteString("  " + safeStyle.Render("a") + " apply source → home    ")
			out.WriteString(safeStyle.Render("c") + " capture home → source    ")
			out.WriteString(safeStyle.Render("u") + " pull + apply\n")
		} else {
			out.WriteString("  " + mutedStyle.Render("apply/capture/update unavailable until chezmoi preview succeeds") + "\n")
		}
		out.WriteString("  " + mutedStyle.Render("↑/↓ scroll   pgup/pgdn page   tab switch view\n"))
		out.WriteString("  " + mutedStyle.Render("s settings   r refresh   q quit without changes"))
	}
	return out.String()
}

func (m *Model) move(delta int) {
	m.scroll = min(max(0, m.scroll+delta), m.maxScroll())
}

func (m *Model) pageSize() int {
	reserved := 14
	if m.snapshot.Notice != "" {
		reserved += 2
	}
	return max(4, m.height-reserved)
}

func (m *Model) maxScroll() int {
	lineCount := len(strings.Split(strings.TrimRight(m.tabContent(), "\n"), "\n"))
	return max(0, lineCount-m.pageSize())
}

func (m *Model) tabContent() string {
	switch m.tab {
	case 0:
		if strings.TrimSpace(m.snapshot.ManagedStatus) == "" {
			return safeStyle.Render("✓ Managed files match the source.") + "\n"
		}
		return "Managed-file drift:\n\n" + m.snapshot.ManagedStatus
	case 1:
		if strings.TrimSpace(m.snapshot.Diff) == "" {
			return safeStyle.Render("✓ No source → home changes.") + "\n"
		}
		return m.snapshot.Diff
	default:
		if strings.TrimSpace(m.snapshot.RepoStatus) == "" {
			return safeStyle.Render("✓ Source repository is clean.") + "\n"
		}
		return m.snapshot.RepoStatus
	}
}

func (m *Model) confirmationText() string {
	switch m.confirming {
	case ActionApply:
		return "Apply the reviewed source state to managed files in your home directory.\nChezmoi will ask for interactive confirmation again."
	case ActionCapture:
		return "Copy managed home-directory changes into the source repository.\nChezmoi will confirm changes; ignored files stay untouched. Git is not committed or pushed."
	case ActionUpdate:
		return "Pull the source repository, recalculate the diff, then apply interactively.\nThis action uses the network and can change managed home files."
	default:
		return ""
	}
}

func viewport(value string, start, lineLimit, width int) string {
	lines := strings.Split(strings.TrimRight(value, "\n"), "\n")
	start = min(max(0, start), max(0, len(lines)-lineLimit))
	end := min(len(lines), start+lineLimit)
	visible := append([]string(nil), lines[start:end]...)
	for index, line := range visible {
		visible[index] = truncate(line, width)
	}
	if len(lines) > lineLimit && len(visible) > 0 {
		position := fmt.Sprintf(" lines %d-%d/%d ", start+1, end, len(lines))
		visible[len(visible)-1] = mutedStyle.Render(position + "· use ↑/↓ or pgup/pgdn")
	}
	return strings.Join(visible, "\n") + "\n"
}

func truncate(value string, width int) string {
	if utf8.RuneCountInString(value) <= width {
		return value
	}
	runes := []rune(value)
	return string(runes[:max(1, width-1)]) + "…"
}

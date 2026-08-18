package syncui

import (
	"testing"

	tea "charm.land/bubbletea/v2"
)

func key(value string) tea.KeyPressMsg {
	return tea.KeyPressMsg(tea.Key{Code: rune(value[0]), Text: value})
}

func TestMutatingActionRequiresConfirmation(t *testing.T) {
	model := New(Snapshot{})
	updated, command := model.Update(key("a"))
	got := updated.(*Model)
	if command != nil || got.confirming != ActionApply || got.result.Action != ActionNone {
		t.Fatalf("apply should enter confirmation first: %#v", got)
	}
	updated, command = got.Update(key("y"))
	got = updated.(*Model)
	if command == nil || got.result.Action != ActionApply {
		t.Fatalf("confirmed apply result = %#v", got.result)
	}
}

func TestBackendErrorDisablesMutation(t *testing.T) {
	model := New(Snapshot{BackendError: "chezmoi not found"})
	updated, _ := model.Update(key("c"))
	got := updated.(*Model)
	if got.confirming != ActionNone || got.result.Action != ActionNone {
		t.Fatalf("backend error should disable capture: %#v", got)
	}
}

func TestQuitIsReadOnly(t *testing.T) {
	model := New(Snapshot{})
	updated, command := model.Update(key("q"))
	got := updated.(*Model)
	if command == nil || !got.result.Canceled || got.result.Action != ActionNone {
		t.Fatalf("unexpected quit result: %#v", got.result)
	}
}

func TestDiffCanScrollInsideTUI(t *testing.T) {
	model := New(Snapshot{Diff: "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n"})
	model.height = 18
	model.tab = 1
	updated, _ := model.Update(key("j"))
	got := updated.(*Model)
	if got.scroll != 1 {
		t.Fatalf("scroll = %d, want 1", got.scroll)
	}
	updated, _ = got.Update(key("G"))
	got = updated.(*Model)
	if got.scroll != got.maxScroll() || got.scroll == 0 {
		t.Fatalf("end scroll = %d, max = %d", got.scroll, got.maxScroll())
	}
}

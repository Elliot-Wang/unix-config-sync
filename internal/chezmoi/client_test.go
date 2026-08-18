package chezmoi

import (
	"context"
	"reflect"
	"testing"
)

type fakeRunner struct {
	name   string
	args   []string
	output []byte
}

func (f *fakeRunner) Run(_ context.Context, name string, args ...string) error {
	f.name = name
	f.args = append([]string(nil), args...)
	return nil
}

func (f *fakeRunner) Output(_ context.Context, name string, args ...string) ([]byte, error) {
	f.name = name
	f.args = append([]string(nil), args...)
	return f.output, nil
}

func TestDiffOutputArgs(t *testing.T) {
	run := &fakeRunner{output: []byte("diff")}
	client := Client{Binary: "chezmoi", ConfigPath: "/tmp/config.json", Runner: run}
	got, err := client.DiffOutput(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"--config", "/tmp/config.json", "--no-pager", "diff"}
	if got != "diff" || !reflect.DeepEqual(run.args, want) {
		t.Fatalf("got %q %#v, want diff %#v", got, run.args, want)
	}
}

func TestApplyArgs(t *testing.T) {
	run := &fakeRunner{}
	client := Client{Binary: "chezmoi", ConfigPath: "/tmp/config.json", Runner: run}
	if err := client.Apply(context.Background(), true); err != nil {
		t.Fatal(err)
	}
	want := []string{"--config", "/tmp/config.json", "--no-pager", "--interactive", "apply"}
	if run.name != "chezmoi" || !reflect.DeepEqual(run.args, want) {
		t.Fatalf("got %s %#v, want chezmoi %#v", run.name, run.args, want)
	}
}

func TestUpdateArgs(t *testing.T) {
	run := &fakeRunner{}
	client := Client{Binary: "chezmoi", ConfigPath: "/tmp/config.json", Runner: run}
	if err := client.Update(context.Background()); err != nil {
		t.Fatal(err)
	}
	want := []string{"--config", "/tmp/config.json", "--no-pager", "--interactive", "update"}
	if !reflect.DeepEqual(run.args, want) {
		t.Fatalf("got %#v, want %#v", run.args, want)
	}
}

func TestReAddArgs(t *testing.T) {
	run := &fakeRunner{}
	client := Client{Binary: "chezmoi", ConfigPath: "/tmp/config.json", Runner: run}
	if err := client.ReAdd(context.Background(), ".zshrc"); err != nil {
		t.Fatal(err)
	}
	want := []string{"--config", "/tmp/config.json", "--interactive", "re-add", ".zshrc"}
	if !reflect.DeepEqual(run.args, want) {
		t.Fatalf("got %#v, want %#v", run.args, want)
	}
}

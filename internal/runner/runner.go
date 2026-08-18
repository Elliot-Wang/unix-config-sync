package runner

import (
	"context"
	"io"
	"os/exec"
)

type Runner interface {
	Run(context.Context, string, ...string) error
	Output(context.Context, string, ...string) ([]byte, error)
}

type Exec struct {
	Stdin  io.Reader
	Stdout io.Writer
	Stderr io.Writer
}

func (e Exec) Run(ctx context.Context, name string, args ...string) error {
	command := exec.CommandContext(ctx, name, args...)
	command.Stdin = e.Stdin
	command.Stdout = e.Stdout
	command.Stderr = e.Stderr
	return command.Run()
}

func (e Exec) Output(ctx context.Context, name string, args ...string) ([]byte, error) {
	command := exec.CommandContext(ctx, name, args...)
	command.Stdin = e.Stdin
	command.Stderr = e.Stderr
	return command.Output()
}

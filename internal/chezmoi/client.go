package chezmoi

import (
	"context"
	"errors"
	"fmt"
	"os/exec"
	"strings"

	"github.com/Elliot-Wang/unix-config-sync/internal/runner"
)

type Client struct {
	Binary     string
	ConfigPath string
	Runner     runner.Runner
}

func (c Client) Available() bool {
	binary := c.Binary
	if binary == "" {
		binary = "chezmoi"
	}
	_, err := exec.LookPath(binary)
	return err == nil
}

func (c Client) Diff(ctx context.Context) error {
	return c.run(ctx, "--no-pager", "diff")
}

func (c Client) DiffOutput(ctx context.Context) (string, error) {
	return c.output(ctx, "--no-pager", "diff")
}

func (c Client) Status(ctx context.Context) error {
	return c.run(ctx, "status")
}

func (c Client) StatusOutput(ctx context.Context) (string, error) {
	return c.output(ctx, "status")
}

func (c Client) Apply(ctx context.Context, interactive bool) error {
	args := []string{"--no-pager"}
	if interactive {
		args = append(args, "--interactive")
	}
	args = append(args, "apply")
	return c.run(ctx, args...)
}

func (c Client) Update(ctx context.Context) error {
	return c.run(ctx, "--no-pager", "--interactive", "update")
}

func (c Client) Doctor(ctx context.Context) error {
	return c.run(ctx, "doctor")
}

func (c Client) ReAdd(ctx context.Context, targets ...string) error {
	args := append([]string{"--interactive", "re-add"}, targets...)
	return c.run(ctx, args...)
}

func (c Client) run(ctx context.Context, args ...string) error {
	if c.Runner == nil {
		return errors.New("runner is required")
	}
	binary := c.Binary
	if binary == "" {
		binary = "chezmoi"
	}
	if c.ConfigPath == "" {
		return errors.New("chezmoi config path is required")
	}
	fullArgs := append([]string{"--config", c.ConfigPath}, args...)
	if err := c.Runner.Run(ctx, binary, fullArgs...); err != nil {
		command := "command"
		for _, arg := range args {
			if !strings.HasPrefix(arg, "-") {
				command = arg
				break
			}
		}
		return fmt.Errorf("chezmoi %s: %w", command, err)
	}
	return nil
}

func (c Client) output(ctx context.Context, args ...string) (string, error) {
	if c.Runner == nil {
		return "", errors.New("runner is required")
	}
	binary := c.Binary
	if binary == "" {
		binary = "chezmoi"
	}
	if c.ConfigPath == "" {
		return "", errors.New("chezmoi config path is required")
	}
	fullArgs := append([]string{"--config", c.ConfigPath}, args...)
	output, err := c.Runner.Output(ctx, binary, fullArgs...)
	if err != nil {
		return "", fmt.Errorf("chezmoi preview: %w", err)
	}
	return string(output), nil
}

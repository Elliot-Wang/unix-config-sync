package main

import (
	"fmt"
	"os"

	"github.com/Elliot-Wang/unix-config-sync/internal/app"
)

func main() {
	if err := app.Run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "unix-sync:", err)
		os.Exit(1)
	}
}

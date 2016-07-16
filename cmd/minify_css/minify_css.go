package main

import (
	"io"
	"os"

	log "github.com/Sirupsen/logrus"
	"github.com/tdewolff/minify"
	"github.com/tdewolff/minify/css"
)

// Exit codes
const (
	ErrInput  = 1
	ErrOutput = 2
	ErrMinify = 3
)

func main() {
	m := minify.New()
	m.AddFunc("text/css", css.Minify)

	var exitCode = 0
	defer os.Exit(exitCode)

	r, err := getFile(os.Args, 1, os.Stdin)
	if err != nil {
		log.WithError(err).Error("failed to open input")
		exitCode = ErrInput
		return
	}
	defer logClose(r, "failed to close input")

	w, err := getFile(os.Args, 2, os.Stdout)
	if err != nil {
		log.WithError(err).Error("failed to open output")
		exitCode = ErrOutput
		return
	}
	defer logClose(w, "failed to close output")

	if err := m.Minify("text/css", w, r); err != nil {
		log.WithError(err).Error("failed to minify")
		exitCode = ErrMinify
		return
	}
}

func getFile(args []string, position int, fallback *os.File) (r *os.File, err error) {
	if len(args) < 1+position {
		return fallback, nil
	}

	return os.Open(args[position])
}

func logClose(c io.Closer, message string) {
	if err := c.Close(); err != nil {
		log.WithError(err).Error(message)
	}
}

package main

import (
	"testing"

	"github.com/zapstore/zsp/v2"
)

func TestZapstoreConfig(t *testing.T) {
	if _, err := zsp.LoadConfig("../../zapstore.yaml"); err != nil {
		t.Fatal(err)
	}
}

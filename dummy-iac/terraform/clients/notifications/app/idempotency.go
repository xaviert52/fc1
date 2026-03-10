package main

import (
	"crypto/sha256"
	"encoding/hex"
	"sync"
	"time"
)

type idempotencyCache struct {
	mu    sync.Mutex
	store map[string]time.Time
	ttl   time.Duration
}

var idemCache = idempotencyCache{
	store: make(map[string]time.Time),
	ttl:   10 * time.Minute,
}

func makeIdempotencyKey(eventType, identityID, flowID string) string {
	h := sha256.Sum256([]byte(eventType + identityID + flowID))
	return hex.EncodeToString(h[:])
}

func (c *idempotencyCache) seen(key string) bool {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()

	// cleanup expirados (simple)
	for k, t := range c.store {
		if now.Sub(t) > c.ttl {
			delete(c.store, k)
		}
	}

	if _, exists := c.store[key]; exists {
		return true
	}

	c.store[key] = now
	return false
}

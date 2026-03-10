package main

import "errors"

func validateEnvelope(e Envelope) error {
	if e.SpecVersion != "1.0" {
		return errors.New("invalid specversion")
	}
	if e.Type == "" {
		return errors.New("missing type")
	}
	if e.Source != "ory.kratos" {
		return errors.New("invalid source")
	}
	if e.ID == "" {
		return errors.New("missing id")
	}
	if e.Time == "" {
		return errors.New("missing time")
	}
	if e.Subject == "" {
		return errors.New("missing subject")
	}
	if e.Data.IdentityID == "" {
		return errors.New("missing data.identity_id")
	}
	if e.Trace.RequestID == "" {
		return errors.New("missing trace.request_id")
	}
	return nil
}

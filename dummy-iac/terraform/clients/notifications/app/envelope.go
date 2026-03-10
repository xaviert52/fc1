package main

type Envelope struct {
	SpecVersion string `json:"specversion"`
	Type        string `json:"type"`
	Source      string `json:"source"`
	ID          string `json:"id"`
	Time        string `json:"time"`
	Subject     string `json:"subject"`
	Data        Data   `json:"data"`
	Trace       Trace  `json:"trace"`
}

type Data struct {
	IdentityID  string `json:"identity_id"`
	FlowID      string `json:"flow_id,omitempty"`
	InviteToken string `json:"invite_token,omitempty"`
}

type Trace struct {
	RequestID string `json:"request_id"`
}

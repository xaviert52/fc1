package main

import "log"

func dispatchNotification(env Envelope) {
	switch env.Type {

	case "identity.registration.created":
		log.Printf(`{"level":"info","msg":"processing_registration","identity_id":"%s","invite_token":"%s"}`, env.Data.IdentityID, env.Data.InviteToken)

		// Si el usuario trajo un token, procesamos el B2B
		if env.Data.InviteToken != "" {
			record, err := processInviteToken(env.Data.InviteToken)
			if err != nil {
				log.Printf(`{"level":"error","msg":"invite_processing_failed","identity_id":"%s","error":"%s"}`, env.Data.IdentityID, err)
			} else {
				// El token es válido, enrolamos en Keto
				err = assignRoleInKeto("Company", record.EmpresaID, record.RolAsignado, env.Data.IdentityID)
				if err != nil {
					log.Printf(`{"level":"error","msg":"keto_assignment_failed","identity_id":"%s","error":"%s"}`, env.Data.IdentityID, err)
				} else {
					log.Printf(`{"level":"info","msg":"user_enrolled_successfully","identity_id":"%s","empresa":"%s","rol":"%s"}`, env.Data.IdentityID, record.EmpresaID, record.RolAsignado)
				}
			}
		} else {
			// Flujo normal sin token (Privilegio mínimo)
			log.Printf(`{"level":"info","msg":"user_created_without_invite","identity_id":"%s"}`, env.Data.IdentityID)
		}

	case "identity.verification.requested":
		log.Printf(`{"level":"info","msg":"email_mock_sent","kind":"verification","identity_id":"%s","request_id":"%s"}`, env.Data.IdentityID, env.Trace.RequestID)

	case "identity.recovery.requested":
		log.Printf(`{"level":"info","msg":"email_mock_sent","kind":"recovery","identity_id":"%s","request_id":"%s"}`, env.Data.IdentityID, env.Trace.RequestID)

	case "identity.settings.updated":
		log.Printf(`{"level":"info","msg":"notification_logged","kind":"settings","identity_id":"%s","request_id":"%s"}`, env.Data.IdentityID, env.Trace.RequestID)

	default:
		log.Printf(`{"level":"warn","msg":"unknown_event_type","type":"%s","request_id":"%s"}`, env.Type, env.Trace.RequestID)
	}
}

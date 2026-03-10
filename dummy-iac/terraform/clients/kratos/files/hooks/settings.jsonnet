function(ctx) {
  specversion: "1.0",
  type: "identity.settings.updated",
  source: "ory.kratos",
  id: ctx.identity.id,
  time: ctx.identity.updated_at,
  subject: "identity/" + ctx.identity.id,
  data: {
    identity_id: ctx.identity.id
  },
  trace: {
    request_id: "N/A"
  }
}
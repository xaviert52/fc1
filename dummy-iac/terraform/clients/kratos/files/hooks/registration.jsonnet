function(ctx) {
  specversion: "1.0",
  type: "identity.registration.created",
  source: "ory.kratos",
  id: ctx.identity.id,
  time: ctx.identity.created_at,
  subject: "identity/" + ctx.identity.id,
  data: {
    identity_id: ctx.identity.id
  },
  trace: {
    request_id: if std.objectHas(ctx, "request") && std.objectHas(ctx.request.headers, "X-Request-Id") then ctx.request.headers["X-Request-Id"][0] else "N/A"
  }
}
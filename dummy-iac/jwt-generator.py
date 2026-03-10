import jwt, time

payload = {
  "iss": "pry-auth",
  "sub": "lab-user",
  "aud": "pry-gateway",
  "scope": "api:read",
  "client_id": "lab-client",
  "iat": int(time.time()),
  "exp": int(time.time()) + 300
}

token = jwt.encode(payload, "lab-secret", algorithm="HS256")
print(token)
FROM golang:1.25-alpine AS build

WORKDIR /app

# 1. Copiamos los archivos de módulos
COPY go.mod ./
# Si se generó el go.sum localmente, inclúyelo:
COPY go.sum* ./ 

# 2. Copiamos el código fuente (CRUCIAL hacerlo antes de tidy)
COPY app/ ./app/

# 3. Descargamos y limpiamos dependencias viendo el código real
RUN go mod tidy

# 4. Compilamos el paquete completo
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o notifications ./app

FROM gcr.io/distroless/base-debian12

WORKDIR /app
COPY --from=build /app/notifications /app/notifications

EXPOSE 8080
ENTRYPOINT ["/app/notifications"]
# Mensajeria Servidor

## Requisitos
- Dart SDK >=3.0
- Docker (opcional)

## Ejecutar local
```bash
dart pub get
dart run bin/server.dart
```

## Ejecutar con Docker
```bash
docker build -t mensajeria_servidor .
docker run -p 8080:8080 mensajeria_servidor
```

## Endpoints
- POST /register {username, password}
- POST /login {username, password}
- WS /ws (requiere token JWT)

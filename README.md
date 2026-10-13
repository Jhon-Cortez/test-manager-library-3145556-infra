# test-manager-library-3145556-infra

> **Prueba técnica · Ficha ADSO 3145556**
> Entrega: **martes 13 de octubre de 2026, a las 5:00 p. m.** (17:00, hora Colombia).

Infraestructura de *Manager Library*: contenedores, red, volúmenes y el motor de base de datos
**vacío**. `docker compose up` levanta el sistema completo con un solo comando (RNF-5, T-20).

## Arranque con un solo comando

```bash
cp .env.example .env   # complete los secretos (Art. IX: nunca se commitea .env)
docker compose up
```

| Servicio | Tecnología | Puerto | Notas |
|---|---|---|---|
| `db` | PostgreSQL 16, servidor en UTC | 5432 | Arranca **sin tablas** |
| `api` | PHP 8.3 / Laravel (repo `api`) | 8000 | `GET /api/v1/health` → `{"status":"ok"}` |
| `app` | React (repo `app`) | 5173 | Build estático servido por nginx |

## La base arranca vacía

Artículo V de la constitución: el motor se levanta vacío y todo el DDL vive en las migraciones de
`api`. Este repositorio **no contiene DDL** (ni tablas, ni índices, ni restricciones). El esquema
`library` aparece al correr las migraciones:

```bash
docker compose exec api php artisan migrate
```

Verificación: 0 tablas antes, 6 después.

```bash
docker compose exec db psql -U library -d library \
  -c "select count(*) from information_schema.tables where table_schema in ('public','library');"
```

## Variables de entorno

Las credenciales del motor y de la red interna están fijas en `docker-compose.yml`. En `.env` van
solo los secretos y los orígenes (artículo IX):

| Variable | Obligatoria | Ejemplo | Generación |
|---|---|---|---|
| `APP_KEY` | sí | `base64:…` | `docker compose run --rm api php artisan key:generate --show` |
| `JWT_SECRET` | sí | cadena larga aleatoria | `openssl rand -hex 32` |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | sí | `admin` / — | solo en `.env`, nunca en el repo |
| `CORS_ORIGIN` | no | `http://localhost:5173` | — |
| `VITE_API_URL` | no | `http://localhost:8000/api/v1` | — |

El resto de la configuración que exige `spec-laravel/plan.md` §2 (en [`test-manager-library-3145556-docs`](https://github.com/code-sena/test-manager-library-3145556-docs))
§2 se resuelve dentro del stack: `DATABASE_URL=postgresql://library:library@db:5432/library`,
`COVERS_DIR=/app/var/covers` (volúmenes `pgdata` y `covers`).

## Frontend

`docker/app.Dockerfile` construye `app` (Vite → `dist/`) y lo sirve con nginx en el puerto 5173.
Mientras el repositorio `app` esté vacío, el servicio sirve un aviso; en cuanto exista su build,
el mismo comando sirve la interfaz completa.

## Comandos útiles

```bash
docker compose logs -f api     # ver la API
docker compose down            # parar el stack (conserva los volúmenes)
```

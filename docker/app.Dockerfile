FROM node:22-alpine AS build

WORKDIR /app

ARG VITE_API_URL=http://localhost:8000/api/v1
ENV VITE_API_URL=${VITE_API_URL}

COPY --from=app . .

RUN if [ -f package.json ]; then \
      if [ -f package-lock.json ]; then npm ci; else npm install; fi; \
      npm run build; \
    else \
      mkdir -p dist; \
      printf '%s\n' \
        '<!doctype html>' \
        '<html lang="es">' \
        '<meta charset="utf-8">' \
        '<meta name="viewport" content="width=device-width, initial-scale=1">' \
        '<title>Manager Library</title>' \
        '<body style="font-family:system-ui;max-width:40rem;margin:4rem auto;padding:0 1rem">' \
        '<h1>Manager Library</h1>' \
        '<p>Frontend pendiente: el repositorio <code>app</code> aun no tiene codigo (T-22).</p>' \
        '</body>' \
        '</html>' > dist/index.html; \
    fi

FROM nginx:1.27-alpine

RUN printf '%s\n' \
      'server {' \
      '    listen 80;' \
      '    root /usr/share/nginx/html;' \
      '    location / {' \
      '        try_files $uri /index.html;' \
      '    }' \
      '}' > /etc/nginx/conf.d/default.conf

COPY --from=build /app/dist /usr/share/nginx/html

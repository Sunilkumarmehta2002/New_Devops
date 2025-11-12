## Pro-vertos — demo DevOps project

This repository contains a small event/ticketing webapp (React + Vite frontend, Express + Mongoose backend) and infrastructure automation (Docker, Terraform, Ansible, GitHub Actions) so you can run the full stack locally or build/push images via CI.

This README explains how to run the project locally using the provided automation, commands to show the outputs, and a focused troubleshooting guide for the two most common problems students see during demos: "I cannot register" and "I cannot login".

## Quick summary

- Frontend (dev): http://localhost:3000 (Vite)
- Backend API: http://localhost:5000 (host port 5000 -> container port 4000)
- Local Mongo (docker): container `pro_mongo` (used automatically when you don't provide an external `MONGO_URL`)

## Run the full stack locally (recommended for class demo)

Use the wrapper script which builds images, applies Terraform (creates the docker containers) and runs Ansible where appropriate.

PowerShell (recommended on Windows):

```powershell
# from repository root
bash -lc "bash run.sh --local"
```

Or if you prefer to run the steps manually in a bash shell:

```bash
# build images (Ansible will build if needed)
bash run.sh --local
# or run terraform directly (example: dev frontend)
cd infra/terraform
terraform init
terraform apply -var='mongo_url=' -var='frontend_mode=dev' -auto-approve
```

Notes:
- Passing `--local` or using `-var='mongo_url='` forces use of the local `pro_mongo` container so the stack works without Atlas.
- If you want the production frontend (nginx) on port 3000, apply Terraform with `-var='frontend_mode=prod'`.

## Quick verification commands (show outputs)

Use these to demonstrate to the class that services are up and responding.

PowerShell examples (Windows):

```powershell
# list relevant containers
docker ps --filter "name=pro_" --format "table {{.Names}}	{{.Status}}	{{.Ports}}"

# backend health endpoint
curl http://localhost:5000/test

# frontend (dev) HTML
curl http://localhost:3000 | Select-String -Pattern "<html" -Quiet; if ($?) { Write-Host "frontend returned HTML" }

# show recent backend logs
docker logs --tail 200 pro_backend

# show recent frontend logs
docker logs --tail 200 pro_frontend

# show mongo logs
docker logs --tail 200 pro_mongo
```

Bash examples:

```bash
docker ps --filter "name=pro_" --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'
curl http://localhost:5000/test
curl -sS http://localhost:3000 | head -n 5
docker logs --tail 200 pro_backend
docker logs --tail 200 pro_frontend
docker logs --tail 200 pro_mongo
```

## How to test register & login via command line (curl)

The frontend posts to the backend endpoints `/register` and `/login`. You can call them directly to verify the API behavior.

Register (example):

```bash
curl -v -H "Content-Type: application/json" \
  -X POST http://localhost:5000/register \
  -d '{"name":"Demo User","email":"demo@example.com","password":"password123"}'
```

Login (example):

```bash
curl -v -H "Content-Type: application/json" \
  -X POST http://localhost:5000/login \
  -d '{"email":"demo@example.com","password":"password123"}'
```

If the API returns a non-2xx response, copy the response body and backend logs for debugging (see troubleshooting below).

## Focused troubleshooting: "I cannot register" or "I cannot login"

These features require three moving parts to be healthy:
1. Backend service started and listening (inside container on port 4000, mapped to host 5000)
2. Backend can connect to MongoDB
3. Frontend can send requests to the backend (same-origin, proxy or correct host/port)

Follow these checks in order. Run each command and show the output when asking for help.

1) Is the backend running and reachable?

```bash
curl -i http://localhost:5000/test
# should return a 200 and a small body like: test ok
```

If this fails:
- Check `docker ps` to see `pro_backend` container status.
- Inspect backend logs: `docker logs --tail 200 pro_backend` — look for error traces.

2) Can the backend reach MongoDB?

- If you used the automation with `--local` or left `MONGO_URL` empty, Terraform will create a `pro_mongo` container and the backend uses `mongodb://pro_mongo:27017/provertos` internally.
- Check mongo container status: `docker ps --filter name=pro_mongo` and `docker logs --tail 200 pro_mongo`.
- If you provided an external Atlas `MONGO_URL`, you may see errors like "MongooseServerSelectionError" or TLS errors in backend logs. Typical fixes:
  - Ensure IP whitelist in Atlas includes the host where backend runs (for local Docker, add your public IP or 0.0.0.0/0 for demo).
  - Check that the connection string is URL-encoded: passwords containing `@` must replace `@` with `%40`.
  - If Atlas requires `tls=true`, ensure the URI includes the correct options.

3) If register/login requests hit the backend but fail with a 4xx or 5xx response

- Copy backend logs around the request time: `docker logs --tail 200 pro_backend` and look for stack traces.
- Look in the API JSON response — it may contain a message (e.g., password validation, missing fields).
- Check the database contents directly:

```bash
# open a mongo shell inside the pro_mongo container (if local mongo)
docker exec -it pro_mongo mongosh --eval "use provertos; db.users.find().pretty()"
```

4) If the frontend UI shows "Registration failed" or "Login failed" but the backend responses look OK

- Open Developer Tools in the browser (F12) and check Console & Network tab.
  - In Network, find the POST `/register` or `/login` request. Inspect:
    - Request URL (ensure it's hitting http://localhost:5000 or the expected base URL)
    - Response status and body
    - Any CORS errors in Console (blocked by CORS)
- The frontend in this repo calls axios.post('/register', ...) — that works when frontend and backend are same origin or when the frontend dev server is proxying API calls to the backend. If you serve the frontend via nginx or a different host, confirm that API calls are routed correctly.

5) Common causes & fixes summary

- MONGO/TLS/Atlas errors: check `MONGO_URL`, whitelist IPs, or use the local mongo fallback (leave MONGO_URL empty and run `bash run.sh --local`).
- Unencoded characters in Mongo password (e.g. `@`) — encode them: `user:pass@word` -> `user:pass%40word`.
- Frontend API path mismatch: the frontend posts to `/register` — ensure your frontend server is proxying or that the browser can reach the backend on port 5000.
- CORS: if browser console shows CORS errors, configure backend to allow the frontend origin (or serve both from same origin via nginx). For local demo, serving both on the same host (Terraform maps frontend and backend appropriately) avoids CORS problems.
- Password hashing/validation errors: check backend logs for thrown errors when creating users, and inspect the `users` collection in Mongo to see if the user was created.

## If you still can't register/login — gather these outputs and paste into your question

1. `docker ps --filter "name=pro_" --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'`
2. `docker logs --tail 200 pro_backend`
3. `docker logs --tail 200 pro_frontend`
4. `docker logs --tail 200 pro_mongo`
5. The exact curl command you used and its full response (headers + body). Use `-v` with curl.
6. Screenshots or text copy of the browser Console errors and the Network request/response for the failing register/login.

## CI & deploy notes (short)

- The GitHub Actions workflow builds backend and frontend images and can optionally deploy to a host if you provide deploy secrets (DEPLOY_HOST, DEPLOY_USER, DEPLOY_SSH_KEY). See `.github/workflows/ci-cd.yml` for details.

## Classroom demo checklist (one-liner)

1. Open terminal, run: `bash run.sh --local`.
2. Wait until `pro_mongo`, `pro_backend`, `pro_frontend` show as Up in `docker ps`.
3. Verify backend: `curl http://localhost:5000/test` → should return `test ok`.
4. Open http://localhost:3000 in your browser and try to register/login.
5. If it fails, run the debugging commands above and collect logs for help.

---

If you'd like, I can also:
- Add a short troubleshooting script that runs the key checks and prints a one-page report you can paste into Slack/Teams, or
- Run `terraform apply -var='frontend_mode=prod'` now to demonstrate the nginx production frontend on port 3000 (I'll only run it if you ask).

If you want the README expanded with screenshots and exact expected responses, tell me where you plan to demo (local laptop, cloud VM, or classroom projector) and I will adjust the instructions accordingly.

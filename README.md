## 🎥 Working Project Video Demonstration
- **Video Title:** Insurance Claim Processing & Fraud Detection Platform Demo (9 Min)
- **Direct GitHub Video Link:** [Click to Download/Watch Demo Video](https://github.com/Astr0876/insurance-claim-processing-platform/releases/download/v1.0.0/demo_video.mp4)
# 🛡️ Insurance Claim Processing & Fraud Detection Platform

> **A Fully Functional Full-Stack Enterprise Web Application** built in strict compliance with the **Software Requirements Specification (SRS)**, **Feasibility Study Report**, and **Requirement Elicitation Reports** authored by Yash Patel & Rudra Patel.

---

## 🌟 Executive Overview

This platform is a **fully working, end-to-end insurance claim adjudication and forensic fraud risk analytics suite**. It replaces legacy paper workflows and static UI prototypes with a live **React + Express.js + MySQL / SQLite** architecture with **100% functional data persistence, real file uploads, deterministic explainable AI fraud detection, and role-based workflows**.

### Key Architectural Pillars:
- **No Mockups / Zero Fake Buttons**: Every claim submission, status transition, document verification, fraud score calculation, and audit entry interacts with real REST APIs and database tables.
- **5 Enterprise User Roles**: Strictly guarded with backend JWT token verification and Role-Based Access Control (RBAC).
- **Explainable 7-Factor Fraud Detection Engine**: Deterministic rule weights evaluating policy velocity, coverage ratio, claim frequency, reporting lag, prior history, document completeness, and red-flag narrative patterns.
- **Dual-Engine Database Resilience**: Native MySQL 8.x schema (`database/schema.sql` and `database/seed.sql`) with automatic zero-configuration fallback to an embedded SQLite database (`database/insurance.sqlite`). Evaluators can test immediately without configuring a local MySQL daemon.
- **Interactive 1-Click Role Switcher**: A sticky **Demo Credentials Bar** at the top of the app allows instant 1-click switching between all 5 user roles.

---

## 👥 User Roles & Workflow Capabilities

| Persona | Role Key | Real Capabilities in Application |
|---|---|---|
| **Policyholder** | `CUSTOMER` | Register account (auto-provisions active policy), submit multi-step claim with PDF/image proof of loss, view customer-safe timeline, track adjudication status, view notifications. |
| **Claims Processor** | `INSURANCE_STAFF` | Search and filter claims queue, review claim dossier, verify/reject uploaded documents, approve/deny claims within authorized limits, request more info. |
| **SIU Fraud Officer** | `FRAUD_INVESTIGATOR` | Special Investigation Unit (SIU) case room, inspect 0–100% anomaly dial, analyze granular explainable rule triggers, record investigative findings, "Confirm Fraud" or "Clear Alert". |
| **Operations Manager** | `MANAGER` | Executive KPIs, settlement throughput, fraud savings ROI ($ prevented), interactive Recharts (financial trends, status mix, line of business), live CSV dataset export. |
| **System Administrator** | `ADMIN` | User & role management directory, provision staff accounts, suspend/reactivate accounts, inspect forensic audit logs with JSON payload viewer, configure platform settings. |

---

## 🔑 Demo Accounts & Instant Login

A sticky demo bar is available at the top of every screen. You can also log in manually using the default password **`Password123!`**:

| Role Persona | Email Address | Default Password | Primary Dashboard |
|---|---|---|---|
| **Policyholder** | `customer@example.com` | `Password123!` | `/customer/dashboard` |
| **Claims Processor** | `staff@example.com` | `Password123!` | `/staff/dashboard` |
| **SIU Fraud Officer** | `fraud@example.com` | `Password123!` | `/fraud/dashboard` |
| **Operations Manager** | `manager@example.com` | `Password123!` | `/manager/dashboard` |
| **System Administrator** | `admin@example.com` | `Password123!` | `/admin/dashboard` |

---

## ⚙️ The Explainable 7-Factor Fraud Engine

Rather than displaying a fake "AI thinking" spinner, the platform executes a **deterministic, explainable rule engine** (`server/services/fraudEngine.js`) that produces a numerical score from 0 to 100% and itemized risk factors:

1. **Coverage Ratio Factor (+25 pts)**: Triggered if claim amount exceeds 80% of total policy coverage limit.
2. **Policy Inception Velocity (+30 pts)**: Triggered if the incident occurred within 30 days of the policy start date.
3. **Claimant Frequency Factor (+20 pts)**: Triggered if claimant filed more than 2 claims in the trailing 12 months.
4. **Reporting Lag Factor (+15 pts)**: Triggered if more than 45 days elapsed between incident date and submission date.
5. **Prior Confirmed Fraud History (+40 pts)**: Triggered if claimant has previous fraudulent claims on record.
6. **Loss Narrative Pattern (+15 pts)**: Scans loss description for forensic red flags (`cash`, `unwitnessed`, `total loss`, `stolen while unattended`, `no police report`, etc.).
7. **Missing Proof of Loss (+15 pts)**: Triggered if a major claim is filed without uploaded evidence documents.

### Severity Tiers:
- **`HIGH` (Score ≥ 70%)**: Flagged with red badge; automatically routed to SIU; approval blocked until reviewed.
- **`MEDIUM` (Score 35% – 69%)**: Flagged with amber badge; requires manual underwriter verification.
- **`LOW` (Score < 35%)**: Standard fast-track processing lane.

---

## 🛠️ Technology Stack

- **Frontend**: React 18, Vite, Tailwind CSS, React Router v6, Axios, Recharts, Lucide React, Framer Motion.
- **Backend**: Node.js, Express.js, JWT (`jsonwebtoken`), `bcryptjs`, Multer multipart file upload.
- **Database**:
  - **MySQL 8.x** via `mysql2/promise` with connection pooling.
  - **SQLite 3** (`better-sqlite3`) embedded resilience fallback.
- **Architecture**: Modular Controller-Service-Repository pattern with immutable audit logging.

---

## 🚀 Quick Start Guide

### Prerequisites:
- **Node.js** (v18.x or later)
- **npm** (v9.x or later)
- *(Optional)* **MySQL Server 8.x** running on port 3306 (if not running, the platform seamlessly uses embedded SQLite).

---

### Step 1: Backend Setup

```bash
# Navigate to the server folder
cd server

# Install backend dependencies
npm install

# Start the Express API server (Default port: 5001)
npm start
```

> **Note on macOS Port 5000**: macOS uses port 5000 for AirPlay Receiver. The server is configured to run on **port 5001** by default to prevent port conflicts.

---

### Step 2: Frontend Setup

Open a new terminal window:

```bash
# Navigate to the client folder
cd client

# Install frontend dependencies
npm install

# Start the Vite development server (Port 3000)
npm run dev
```

Open your browser at **[http://localhost:3000](http://localhost:3000)**.

---

### Step 3: (Optional) Configuring Local MySQL

By default, the server runs in `DB_TYPE=auto` mode. If your local MySQL server is running, it will automatically connect and seed if needed. To explicitly configure MySQL credentials:

1. Create a database:
   ```sql
   CREATE DATABASE insurance_claim_db;
   ```
2. Import schema and seed fixtures:
   ```bash
   mysql -u root -p insurance_claim_db < database/schema.sql
   mysql -u root -p insurance_claim_db < database/seed.sql
   ```
3. Set your credentials in `server/.env`:
   ```env
   DB_TYPE=mysql
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=your_password
   DB_NAME=insurance_claim_db
   ```

---

## 📂 Project Structure

```
LockIn/
├── client/                          # React Frontend (Vite + Tailwind CSS)
│   ├── src/
│   │   ├── components/
│   │   │   └── common/             # Badges, Buttons, Modals, DemoCredentialsBar
│   │   ├── context/
│   │   │   └── AuthContext.jsx      # JWT Auth Provider & 1-click role switcher
│   │   ├── layouts/
│   │   │   ├── PublicLayout.jsx     # Navigation, hero container & footer
│   │   │   └── DashboardLayout.jsx  # Enterprise RBAC dashboard layout
│   │   ├── pages/
│   │   │   ├── public/              # Home, How It Works, Features, Login, Register
│   │   │   ├── customer/            # Dashboard, Submit Wizard, History, Details, Profile
│   │   │   ├── staff/               # Staff Dashboard, Claims Queue, Adjudication Review
│   │   │   ├── fraud/               # SIU Fraud Dashboard, Case Investigation Room
│   │   │   ├── manager/             # Executive KPIs, Recharts Analytics, CSV Export
│   │   │   └── admin/               # User Directory, Audit Trail, System Settings
│   │   ├── services/
│   │   │   └── api.js               # Axios client with JWT interceptors
│   │   ├── App.jsx                  # Route definitions & ProtectedRoute guards
│   │   └── main.jsx                 # Entrypoint
│   ├── package.json
│   └── vite.config.js
│
├── server/                          # Express.js REST API Backend
│   ├── config/
│   │   └── db.js                    # Dual-engine MySQL / SQLite database adapter
│   ├── controllers/
│   │   ├── authController.js        # Register, Login, Me with password hashing
│   │   ├── claimController.js       # Create claim, queue, details, status transitions
│   │   ├── documentController.js    # Multer uploads, verification, download stream
│   │   ├── fraudController.js       # Queue, explainable factors, SIU findings
│   │   ├── reportController.js      # Executive summaries, monthly trends, CSV export
│   │   ├── userController.js        # RBAC user management, roles, account toggles
│   │   ├── auditController.js       # Forensic audit trail logs
│   │   └── settingsController.js    # Dynamic system thresholds
│   ├── middleware/
│   │   ├── auth.js                  # JWT token verify & requireRoles() guards
│   │   ├── upload.js                # Multer disk storage (10MB limit, mime filter)
│   │   └── auditLogger.js           # Immutable database audit logger
│   ├── services/
│   │   ├── fraudEngine.js           # Explainable 7-factor rule scoring engine
│   │   └── notificationService.js   # User and role broadcast notifications
│   ├── uploads/                     # Multer storage directory for proof of loss
│   ├── server.js                    # Express app root (Port 5001)
│   └── package.json
│
├── database/                        # Database Schemas & Seed Data
│   ├── schema.sql                   # MySQL DDL for all 11 normalized tables
│   ├── seed.sql                     # Seed fixtures for 5 roles and test claims
│   └── insurance.sqlite             # Pre-seeded SQLite database for zero-config run
│
├── .env.example                     # Environment template
└── README.md                        # Documentation
```

---

## 📡 Core REST API Endpoints

### Authentication
- `POST /api/auth/register` — Create policyholder account (auto-issues active policy)
- `POST /api/auth/login` — Sign in, verify password with bcrypt, issue JWT
- `GET /api/auth/me` — Retrieve active user session and role

### Claims Adjudication
- `GET /api/claims` — Filterable claims queue (scoped by role)
- `GET /api/claims/:id` — Full claim dossier, timeline, and documents
- `POST /api/claims` — Submit claim with multipart file uploads (auto-runs fraud engine)
- `PUT /api/claims/:id/status` — Approve, reject, or request more information

### Evidence Document Management
- `POST /api/documents/:claimId/upload` — Upload supporting documents via Multer
- `PUT /api/documents/:id/verify` — Staff verification (`VERIFIED`, `REJECTED`, `PENDING`)
- `GET /api/documents/:id/download` — Stream / download uploaded file

### Special Investigation Unit (Fraud)
- `GET /api/fraud/queue` — Filter claims by fraud severity (`HIGH`, `MEDIUM`)
- `GET /api/fraud/:claimId` — Full forensic dossier with explainable rule breakdown
- `PUT /api/fraud/:claimId/investigate` — Record findings; Confirm Fraud or Clear Alert

### Executive Reports & Analytics
- `GET /api/reports/summary` — Total volume, payout total, fraud savings ROI, approval rate
- `GET /api/reports/trends` — Monthly claims vs settlement trajectory
- `GET /api/reports/status` — Current status distribution
- `GET /api/reports/types` — Claims by insurance line (Health, Auto, Life, Property)
- `GET /api/reports/export` — Formatted dataset for browser CSV export

### Administration & Security
- `GET /api/users` — Directory of users across all roles
- `POST /api/users` — Provision new staff account
- `PUT /api/users/:id/role` — Update RBAC role assignment
- `PUT /api/users/:id/status` — Toggle active / suspended status
- `GET /api/audit-logs` — Immutable forensic audit trail with JSON payload viewer
- `GET /api/settings` — Platform configuration parameters
- `PUT /api/settings` — Update fraud thresholds and compliance rules

---

## 🧪 Verification & Testing Completed

1. **Dual Database Adapter**: Verified that both MySQL pool connection and SQLite fallback query identical schema tables and seed data.
2. **Explainable Fraud Engine**: Verified all 7 rule factors calculate deterministic weights and produce human-readable rationale.
3. **RBAC & Security**: Verified backend unauthorized HTTP 403 blocks when an unauthorized role tries to approve or access restricted endpoints.
4. **Vite Production Build**: Executed `npm run build` in `/client` with **0 errors**; all 2,394 modules bundled cleanly.
5. **CSV Exporter**: Tested data export generation with real database records.

---

## 📄 Academic Project Reference

This system was designed and developed for the **Software Engineering Capstone Lab Project**, based on the formal specifications in:
- **Software Requirements Specification (SRS)**
- **Feasibility Study Report**
- **Requirement Elicitation & Analysis Reports**
- *Student Authors*: Yash Patel & Rudra Patel

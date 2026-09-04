# 🏃 RaceDay — Event Management System

### Part 1: System Planning and Database Design

---

## 📋 Project Overview

| | |
|---|---|
| **Student Name** | Botshelo Letebele |
| **Student Number** | ST10478568 |
| **Module** | PROG6212 – Part 1 |
| **Repository** | [github.com/botletebele66/PROG6212-POE](https://github.com/botletebele66/PROG6212-POE.git) |

---

## 📁 Project Structure

```
PROG6212-POE/
│
├── README.md                          # This file - project documentation
│
├── 📁 docs/                           # All planning documentation
│   ├── ERD_RaceEventSystem.png        # Entity Relationship Diagram
│   ├── API_Endpoint_Plan.pdf          # Complete API endpoint specifications
│   └── database-schema.sql            # SQL Server database script
│
├── 📁 .github/                        # GitHub configuration
│   └── 📁 workflows/
│       └── ci.yml                     # CI/CD workflow for validation
│
├── 📁 src/                            # Source code (to be added in Part 2)
│   └── (API code will be added here)
│
├── 📁 tests/                          # Unit tests (to be added in Part 2)
│   └── (Test code will be added here)
│
└── .gitignore                         # Git ignore file
```

---

## 🏃 System Description

**RaceDay** is a full-stack web-based event management platform designed specifically for the South African road running, walking, and cycling community. The platform bridges the gap between event organisers and participants by providing a centralised, digital solution for event management, registration, and performance tracking.

### The Problem We Solve

South Africa has a rich road events culture — from the iconic **Comrades Marathon** between Pietermaritzburg and Durban, to the **Cape Town Cycle Tour**, the **Soweto Marathon**, the **Two Oceans**, and hundreds of community walks, park runs, and charity cycling events held in towns and cities across the country every weekend.

Despite the enormous participation these events attract, many are still managed through paper-based registration, spreadsheets, and disconnected communication channels — leaving organisers overwhelmed and participants underserved.

**RaceDay digitises and streamlines this entire process**, making event management efficient, accessible, and enjoyable for all.

---

## 👥 User Roles

### 🏢 Organiser
- Create, edit, and delete events
- Manage event categories (distances, entry fees, age restrictions)
- Capture participant results after an event
- View all enrolments for their events

### 🏃 Participant
- Create an account and log in
- Browse upcoming events and view event details
- Enrol in an event by selecting a category
- View their own enrolment history and personal race results
- Prepare for race day using route and weather information *(to be integrated in later parts)*

---

## 📊 Database Design

### Entity Relationship Diagram (ERD)

The database consists of **7 entities** with the following relationships:

| Entity | Description |
|---|---|
| **Users** | Base account table shared by both roles |
| **Organiser** | 1-to-1 extension of Users for event organisers |
| **Participant** | 1-to-1 extension of Users for race entrants |
| **Event** | A race/event created by an Organiser |
| **EventCategory** | A distance/fee category within an Event |
| **Enrolment** | Junction table connecting Participant to EventCategory |
| **Result** | Finishing time/rank for a completed Enrolment |

### Key Design Decisions

- **Role Separation** — `Users` is split from `Organiser`/`Participant` to avoid nullable columns and keep role-specific data properly scoped.
- **Many-to-Many Resolution** — The `Enrolment` table resolves the many-to-many relationship between `Participants` and `EventCategories`.
- **Result Separation** — `Result` is kept separate from `Enrolment` since not every enrolment has a result yet (only completed races).
- **Data Integrity** — `UNIQUE(ParticipantID, CategoryID)` on `Enrolment` prevents duplicate registrations.
- **Cascade Deletes** — Applied down the ownership chain to maintain data consistency.

---

## 🗄️ SQL Script

The database schema (`/docs/database-schema.sql`) includes:

- ✅ `CREATE TABLE` statements for all 7 entities
- ✅ All primary keys, foreign keys, and constraints
- ✅ Triggers for automatic `UpdatedDate` tracking
- ✅ Comprehensive indexes for performance
- ✅ Realistic seed data:
  - 2 Organisers
  - 2 Participants
  - 3 Events
  - 5 Categories
  - 3 Enrolments
  - 2 Results
- ✅ Transaction-based seed data with error handling
- ✅ Data verification queries

---

## 🔗 API Endpoint Plan

### Core Endpoints by Resource

| Resource | Methods |
|---|---|
| **Authentication** | Register, Login, Logout, Refresh Token |
| **Users** | Get, Update, Role-specific profile |
| **Events** | List, Details, Create, Edit, Delete |
| **Categories** | List, Add, Edit, Delete |
| **Enrolments** | List, Create, Withdraw, Event enrolments |
| **Results** | Capture results |

### Third-Party API Integration (Planned)

**Google Maps Platform APIs**
- Routes API — Compute routes with real-time traffic
- Geocoding API — Convert addresses to coordinates
- Places API — Autocomplete and place details
- Elevation API — Elevation data for routes

**Weather APIs**
- Google Weather API *(recommended for Maps integration)*
- OpenWeatherMap *(third-party alternative)*
- Weatherstack *(third-party alternative)*

---

## 🔧 CI/CD Pipeline

### GitHub Actions Workflow

The repository includes a CI/CD workflow (`/.github/workflows/ci.yml`) that:

- ✅ Validates repository structure
- ✅ Checks for required `/docs` folder
- ✅ Verifies presence of all planning documents
- ✅ Runs on every push to the `main` branch

### Build Status

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)

<img width="991" height="260" alt="Screenshot 2026-09-04 090833" src="https://github.com/user-attachments/assets/3ef6f730-a7ad-4d0b-b646-8970d0894171" />

---

## 🎥 Video Presentation

**[Watch the Video Presentation](#)** The link will be provided

The video covers:

- 📊 ERD walkthrough and design decisions
- 🔗 API endpoint plan explanation
- 🗄️ SQL script demonstration (run live in SSMS)
- 📁 Repository structure overview

---

## 🚀 What's Next — Part 2

The following will be added in Part 2 of the PROG6212 POE:

- API implementation in `/src`
- Unit tests in `/tests`
- Integration of the Google Maps and Weather APIs outlined above

---

*Maintained by Botshelo Letebele (ST10478568) — PROG6212*

# WorkPass 🚀  
### Turning Gig Work into Bank‑Trusted Income

WorkPass is a cross‑platform Flutter application that helps **gig workers prove income, stability, and trustworthiness** so they can gain access to real financial services such as **loans, BNPL, insurance, and banking products** — even without payslips or formal employment.

It also includes a **Bank Officer dashboard** to view worker risk profiles using a transparent scoring system called **WorkScore**.

---

## 🌟 Problem

Millions of gig workers earn consistently through platforms like:
- Swiggy, Zomato
- Uber, Ola
- Zepto, Rapido, OYO, etc.

But banks struggle to assess them due to:
- scattered income proof
- lack of salary slips
- unverifiable work history

As a result, genuine workers are rejected or offered unfair interest rates.

---

## ✅ Solution: WorkPass

WorkPass creates a structured and verifiable work identity.

### For Gig Workers
- Add daily work entries (platform, hours, earnings)
- Optional proof upload (for verification)
- View dashboard with earnings & risk
- Get transparent breakdown of WorkScore

### For Banks / Financial Institutions
- Read‑only dashboard of workers
- View income history, verification ratio, stability
- Risk level badges (Low / Medium / High)
- Score transparency (how score is calculated)

---

## 🧠 WorkScore (Transparent Scoring)

WorkScore is computed using:
WorkScore =
(0.4 × MonthlyIncomeScore) +
(0.3 × StabilityScore) +
(0.3 × VerificationScore)


This ensures trust and fairness for workers and lenders.

---

## 🛠 Tech Stack

- **Flutter (Material 3)** – UI & cross-platform app (Web / Android / iOS-ready)
- **Supabase** – Database + APIs
- **PostgreSQL** – structured data storage
- **Cursor** – rapid development + agent-assisted coding

---

## 📦 Database Schema (Supabase)

Main tables used:
- `users`
- `work_entries`
- `work_scores`
- `institution_users`

---

## ✨ Key Features

-✅ Premium UI inspired by **Apple / Netflix / fintech apps**  
-✅ Worker Dashboard (income, history, WorkScore)  
-✅ Bank Officer Dashboard (worker risk analytics)  
-✅ Add Work Entry flow (proof optional)  
-✅ Demo-ready placeholder data support  
-✅ Supabase integration (real DB data supported)

---

## 🧪 Sample Data
You can seed the database with mock worker entries to demonstrate:

-✅ Stable monthly income
-✅ Verification ratios
-✅ Risk scoring (WorkScore)

## 🎥 Demo Walkthrough (Suggested for Judges)
### 1. Open Worker Dashboard

### 2. Add Work Entry (proof optional)

### 3. Observe:
- ✅ Entry added successfully
- ✅ History updates instantly
- ✅ WorkScore transparency visible

### 4. Switch to Bank Officer Dashboard

### 5. Review:
- Worker list + profiles
- Risk levels
- Score breakdown

## 📌 Future Scope
- 🔗 Direct gig platform integrations (Swiggy / Zomato / Ola via partnerships)
- 🪪 KYC & verified identity linkage
-📍 Real-time verification signals (GPS, receipts, platform sync)
- 💸 Loan & payout pipeline (UPI + bank partnerships)
- 🤖 Explainable AI-based risk scoring


# SOFTWARE ENGINEERING LAB
## RMMM PLAN — COMPLETE STEP-BY-STEP IMPLEMENTATION MANUAL
### Risk Mitigation, Monitoring and Management Plan

**Course:** Software Engineering Laboratory  
**Project Title:** Insurance Claim Processing & Fraud Detection Platform  
**Authors:** Yash Patel & Rudra Patel  
**Tools Used:** Node.js, Express.js, React.js, Vite, MySQL / SQLite, Multer, JWT  

---

## 1. Lab Objective
To prepare a comprehensive Risk Mitigation, Monitoring, and Management (RMMM) Plan by identifying potential software project risks, estimating their probability and impact, assigning priority levels, and defining proactive mitigation, continuous monitoring, and reactive contingency management actions.

---

## 2. What Students Submit
- **Case-Study Summary** (System understanding, users, functions, critical data)
- **Risk Identification** (5–8 domain-specific software risks categorized)
- **Probability & Impact Analysis** (Prioritization using standard matrix rules)
- **Complete RMMM Table** (Mitigation, Monitoring, and Management actions for all risks)
- **Risk Register** (Owners, priorities, and operational statuses)
- **Risk Priority Matrix** (3×3 visual mapping grid)
- **Six-Step Reasoning for One Core Risk** (In-depth analysis of high-priority risk)
- **Conclusion / Result** (Formal conclusion statement based on lab template)

---

## 3. Step 1 — Understand Your Assigned Case Study

| Item | Student Entry |
|---|---|
| **Case Study Name** | **Insurance Claim Processing & Fraud Detection Platform** |
| **Purpose** | A secure, full-stack enterprise web application designed to automate the insurance claim lifecycle—from online submission and multi-document verification to automated explainable fraud detection, SIU investigation, staff adjudication (approval/rejection), real-time status tracking, and immutable audit logging. |
| **Main Users** | 1. **Policyholder (Customer)**: Submits claims, uploads proof of loss, tracks status.<br>2. **Claims Processor (Insurance Staff)**: Reviews claims, verifies documents, approves/rejects payouts.<br>3. **Fraud Investigation Officer (SIU)**: Analyzes suspicious claims, evaluates risk factors, confirms fraud or clears alerts.<br>4. **Operations Manager**: Monitors operational velocity, financial loss ratios, fraud savings ROI, and exports reports.<br>5. **System Administrator**: Manages RBAC user privileges, inspects audit logs, and configures engine thresholds. |
| **Major Functions** | • User authentication & Role-Based Access Control (RBAC via JWT + bcrypt)<br>• Multi-step Claim Submission Wizard with document attachments<br>• Automated 7-factor explainable fraud-risk scoring engine<br>• Document verification workbench (Verify / Reject)<br>• Special Investigation Unit (SIU) Case Room<br>• Claim adjudication workflow with policy coverage limits validation<br>• Real-time in-app notification dispatch and customer claim tracking timeline<br>• Executive reports, financial trends, and live CSV dataset export<br>• Immutable system-wide forensic audit logging |
| **Important Data / Resources** | User credentials & passwords (`bcrypt`), Policyholder PII, Policy limits & deductibles, Claims master records, Uploaded proof of loss files (PDF/Images stored via Multer in `server/uploads/`), Fraud risk scores & serialized rule JSON, Claim status transition histories, Forensic audit trail records, and MySQL / SQLite database instances. |

---

## 4. Step 2 — Identify 5–8 Risks

| ID | Risk Description | Category |
|---|---|---|
| **R1** | **Database Failure & Claim Record Loss**: Unavailability or corruption of the relational database leading to loss of active claims, policy mappings, or adjudication status history. | Data / Technical |
| **R2** | **Fraud Risk Engine Misclassification (False Negatives)**: Sophisticated staged claims or inflated invoices bypassing automated rule thresholds, resulting in illegitimate settlement payouts. | Algorithm / Business |
| **R3** | **Unauthorized Access & RBAC Privilege Escalation**: Attackers forging JWT tokens or manipulating API parameters to gain staff/admin permissions and illegally approve claims. | Security |
| **R4** | **Malicious File Upload & Storage Exhaustion**: Claimants uploading malicious executable payloads, infected PDFs, or abnormally large files exhausting server disk quotas. | Security / Technical |
| **R5** | **Concurrent Claim Status Race Conditions**: Multiple claims staff members attempting simultaneous adjudication on the same claim dossier, causing double-settlement or conflicting statuses. | Concurrency / Performance |
| **R6** | **Audit Trail Inconsistency & Non-Compliance**: Application crashes or unhandled database exceptions resulting in claim status changes occurring without corresponding immutable audit records. | Compliance / Data |
| **R7** | **Third-Party Notification & Alert Delivery Failure**: Network outages or SMTP failures preventing timely delivery of critical status change notifications to policyholders. | External Dependency |
| **R8** | **Project Schedule Delay in Multi-Role Integration**: Complex synchronization between 5 distinct dashboard workspaces and workflow dependencies causing project delivery slippage. | Schedule / Management |

---

## 5. Step 3 — Assign Probability and Impact

### Evaluation Criteria:
- **Probability**: 
  - *Low*: Unlikely to occur
  - *Medium*: May occur during normal operation
  - *High*: Likely to occur if uncontrolled
- **Impact**:
  - *Low*: Small effect; system operations continue
  - *Medium*: Moderate operational hindrance; requires manual workaround
  - *High*: Serious operational interruption, regulatory penalty, or direct financial loss
- **Priority Logic**:
  - $\text{High Prob.} + \text{High Impact} \rightarrow \mathbf{High}$
  - $\text{High Prob.} + \text{Medium Impact} \rightarrow \mathbf{High}$
  - $\text{Medium Prob.} + \text{High Impact} \rightarrow \mathbf{High}$
  - $\text{Medium Prob.} + \text{Medium Impact} \rightarrow \mathbf{Medium}$
  - $\text{Low Prob.} + \text{High Impact} \rightarrow \mathbf{High}$
  - $\text{Medium Prob.} + \text{Low Impact} \rightarrow \mathbf{Low}$
  - $\text{Low Prob.} + \text{Low Impact} \rightarrow \mathbf{Low}$

### Risk Analysis Table:

| ID | Risk Description | Probability | Impact | Priority |
|---|---|---|---|---|
| **R1** | Database failure / data loss | Medium | High | **High** |
| **R2** | Fraud risk engine misclassification | Medium | High | **High** |
| **R3** | Unauthorized access / privilege escalation | Low | High | **High** |
| **R4** | Malicious file upload / storage exhaustion | Medium | Medium | **Medium** |
| **R5** | Concurrent claim status race conditions | Medium | High | **High** |
| **R6** | Audit trail inconsistency / non-compliance | Low | High | **Medium** |
| **R7** | Notification delivery failure | Medium | Low | **Low** |
| **R8** | Project schedule delay | High | Medium | **High** |

---

## 6. Step 4 — Prepare the COMPLETE RMMM Table

> **Mitigation:** Actions taken *before* the risk occurs to reduce probability or impact.  
> **Monitoring:** Warning signs, error metrics, and health indicators tracked over time.  
> **Management:** Contingency procedures executed *when* the risk occurs to restore stability.

| ID | Risk | Prob. | Impact | Priority | Mitigation (Before) | Monitoring (During) | Management (After / Contingency) |
|---|---|---|---|---|---|---|---|
| **R1** | Database failure / data loss | M | H | **H** | Implement dual-engine resilience adapter (`server/config/db.js`) supporting automated SQLite fallback if MySQL is offline; schedule automated SQL dumps; use connection pooling with keepalive. | Monitor connection pool latency, query timeouts, failed connection retries, and disk space usage on the database host. | Automatically trigger SQLite secondary failover; restore latest consistent backup snapshot; replay pending claim events from access logs. |
| **R2** | Fraud engine misclassification | M | H | **H** | Implement explainable 7-factor deterministic scoring engine; enforce mandatory SIU manual review on claims $\ge \$40,000$ or risk score $\ge 65\%$; require verified documents before payout. | Track ratio of claims flagged vs cleared; analyze underwriter override frequency; audit post-payout loss ratios and sample-check 5% of low-risk claims. | Immediately freeze pending payout disbursements; adjust risk cutoffs via System Settings (`/admin/settings`); add claimant to `RULE_PRIOR_SUSPICIOUS_HISTORY` (+25 penalty). |
| **R3** | Unauthorized access / RBAC bypass | L | H | **H** | Sign JWTs with a high-entropy secret; enforce backend `requireRoles()` middleware on all protected API endpoints; hash passwords with `bcryptjs` (salt rounds = 10). | Inspect audit logs for spikes in HTTP 401/403 responses, brute-force login attempts, and mismatched user session tokens. | Invalidate compromised JWT tokens; suspend compromised user accounts via User Management (`/admin/users`); patch exploited route controller. |
| **R4** | Malicious file upload / storage exhaustion | M | M | **M** | Enforce Multer disk storage validation with strict 10MB file limit; whitelist MIME types (`application/pdf`, `image/jpeg`, `image/png`); sanitize uploaded filenames. | Track disk space in `server/uploads/`; log rejected file upload attempts and invalid MIME type exceptions. | Purge orphan upload files; expand server disk allocation; quarantine flagged files for security analysis. |
| **R5** | Concurrent status race conditions | M | H | **H** | Use atomic database operations; check current status before executing transition; enforce optimistic/pessimistic row locking during approval. | Monitor database lock wait times, duplicate status change alerts, and collision errors in claim adjudication logs. | Reconcile double-settlement claims; roll back unauthorized secondary updates; reset claim state to `UNDER_REVIEW` with an audit note. |
| **R6** | Audit trail inconsistency | L | H | **M** | Execute database mutations and `logAudit()` within synchronous execution flow; enforce foreign key integrity (`ON DELETE RESTRICT` on roles). | Run scheduled verification comparing claim status transitions in `claim_status_history` against total recorded rows in `audit_logs`. | Reconstruct missing audit records using structured HTTP access logs; log compliance incident report; flag affected claims for manual re-audit. |
| **R7** | Notification delivery failure | M | L | **L** | Implement asynchronous background notification handling with retry backoff; persist all notifications in the database `notifications` table. | Monitor notification delivery error rates, external API response times, and unread notification accumulation in queue. | Resend failed notification queue from database table; display persistent in-app notification banners on the customer dashboard. |
| **R8** | Project schedule delay | H | M | **H** | Decompose architecture into modular milestones (Database $\rightarrow$ Auth $\rightarrow$ Claims $\rightarrow$ Fraud $\rightarrow$ Analytics); maintain structured WBS; conduct weekly milestones. | Track planned vs actual feature completion across sprints; monitor Git commit cadence and open task backlog. | Reassign developer tasks; temporarily descope non-critical visual animations to safeguard core adjudication and fraud functionality. |

---

## 7. Step 5 — Prepare the Risk Register

| ID | Risk Description | Probability | Impact | Priority | Risk Owner | Status |
|---|---|---|---|---|---|---|
| **R1** | Database Failure & Claim Record Loss | Medium | High | High | Database Lead / DBA | **Monitoring** |
| **R2** | Fraud Risk Engine Misclassification | Medium | High | High | SIU Lead / Algorithm Engineer | **Open** |
| **R3** | Unauthorized Access & RBAC Bypass | Low | High | High | Security Architect | **Controlled** |
| **R4** | Malicious File Upload & Storage Exhaustion | Medium | Medium | Medium | Backend Engineer | **Controlled** |
| **R5** | Concurrent Status Race Conditions | Medium | High | High | Senior Backend Developer | **Monitoring** |
| **R6** | Audit Trail Inconsistency | Low | High | Medium | Quality & Compliance Lead | **Controlled** |
| **R7** | Notification Delivery Failure | Medium | Low | Low | Full-Stack Developer | **Open** |
| **R8** | Project Schedule Delay | High | Medium | High | Project Manager | **Monitoring** |

*Status Definitions:*
- **Open**: Active risk under investigation with initial controls in place.
- **Monitoring**: Action plan implemented; continuously tracking warning thresholds.
- **Controlled**: Mitigation measures fully operational; residual risk is acceptable.
- **Closed**: Risk no longer applicable to the current phase of the project.

---

## 8. Step 6 — Risk Priority Matrix (3×3 Grid)

| Probability \ Impact | Low Impact | Medium Impact | High Impact |
|:---|:---:|:---:|:---:|
| **High Probability** | — | **R8** *(Project Schedule Delay)* | — |
| **Medium Probability** | **R7** *(Notification Failure)* | **R4** *(File Upload / Storage)* | **R1** *(Database Failure)*<br>**R2** *(Fraud Misclassification)*<br>**R5** *(Concurrency Collision)* |
| **Low Probability** | — | — | **R3** *(Unauthorized RBAC Access)*<br>**R6** *(Audit Trail Loss)* |

---

## 9. Six-Step Reasoning for One Core Risk

### Focused Case Study: **Risk R2 — Fraud Risk Engine Misclassification (False Negatives)**

1. **Identify**:
   - A fraudulent claimant files a staged loss, submits altered medical receipts, or exaggerates damages. If the automated engine fails to detect these anomalies, an illegitimate claim of up to \$50,000 could be approved and disbursed, creating financial loss and compliance violations.
2. **Analyze**:
   - **Probability = Medium** (fraud attempts are frequent in digital insurance portals).
   - **Impact = High** (direct monetary loss, underwriting loss-ratio inflation, legal liabilities).
   - **Priority = High**.
3. **Mitigate**:
   - Design an explainable 7-factor deterministic engine evaluating:
     1. Coverage exhaustion ratio ($\ge 85\% \rightarrow +25$ pts).
     2. Inception velocity ($\le 30$ days from policy start $\rightarrow +22$ pts).
     3. Prior claim frequency ($\ge 2$ claims in 6 months $\rightarrow +20$ pts).
     4. Extreme reporting lag ($>90$ days $\rightarrow +14$ pts).
     5. Missing proof of loss documents ($+18$ pts).
     6. Forensic loss keywords (`"unattended"`, `"cash only"`, etc. $\rightarrow +12$ pts).
     7. Prior rejected or fraudulent claims ($\rightarrow +25$ pts).
   - Enforce an architectural hard-stop: Claims scoring $\ge 65\%$ or exceeding \$40,000 are locked from staff approval until an SIU Officer conducts an investigation.
4. **Monitor**:
   - Review executive fraud metrics in `/manager/reports` to track the percentage of claims flagged vs cleared.
   - Track underwriter override patterns where flagged claims are manually cleared.
   - Conduct random quality audits on 5% of automatically approved low-risk claims.
5. **Manage**:
   - If an approved claim is subsequently discovered to be fraudulent, immediately suspend pending financial disbursements.
   - Update threshold cutoffs dynamically via System Settings (`/admin/settings`).
   - Add the policyholder's ID to `RULE_PRIOR_SUSPICIOUS_HISTORY`, automatically applying a +25 risk penalty to all future submissions.
6. **Record**:
   - Log the incident in the **Risk Register** under status **Monitoring**, assigned to the SIU Lead, and record the full anomaly trace in the `fraud_analysis` database table.

---

## 10. Result / Conclusion

The RMMM Plan was prepared for the **Insurance Claim Processing & Fraud Detection Platform** system. **8** potential risks were identified and analyzed based on probability and impact. Each risk was assigned a priority and appropriate mitigation, monitoring, and management actions were defined. The prepared plan provides a structured approach for handling risks that may affect project schedule, cost, quality, security, or successful completion.

---

## 11. Final Student Checklist

| Verification Item | Status | Notes |
|---|:---:|---|
| Case study is clearly described | **YES** | Platform purpose, 5 user roles, and core modules fully defined. |
| 5–8 relevant risks are identified | **YES** | Exactly 8 domain-specific technical, algorithmic, and security risks identified. |
| Probability and impact are assigned | **YES** | Assigned using Low/Medium/High qualitative scales. |
| Priority is assigned logically | **YES** | Evaluated via standard Software Engineering Risk Priority Guide. |
| Complete RMMM table contains all three actions | **YES** | Detailed, concrete actions provided for Mitigation, Monitoring, and Management without vague phrases. |
| Risk register is completed | **YES** | Complete with assigned Risk Owners and operational statuses. |
| Conclusion/result is included | **YES** | Formatted strictly adhering to Section 16 of the SE Lab Manual. |
| Risks and actions are specific to the assigned case study | **YES** | Grounded in the actual project codebase (MySQL/SQLite, JWT, Multer, 7-factor engine). |

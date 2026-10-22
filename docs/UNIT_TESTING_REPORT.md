# SOFTWARE ENGINEERING LAB REPORT
## UNIT TESTING IMPLEMENTATION (10 TEST CASES)
### Test Framework: JUnit / Node Test Runner (8 PASS, 2 FAIL)

**Course:** Software Engineering Laboratory  
**Project Title:** Insurance Claim Processing & Fraud Detection Platform  
**Authors:** Yash Patel & Rudra Patel  
**Test Distribution:**  
- **Module 1 (Claim Submission & Document Management):** 5 Test Cases (4 PASS, 1 FAIL)  
- **Module 2 (Fraud Risk Detection & Adjudication):** 5 Test Cases (4 PASS, 1 FAIL)  
- **Total:** 10 Test Cases (8 PASS, 2 FAIL)

---

## 1. Summary of Test Cases

| Test Case ID | Module | Test Scenario & Objective | Input Data | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|:---:|
| **TC_MOD1_01** | Module 1 | Validate Claim ID format adhering to `CLM-YYYY-XXXX` | `"CLM-2026-4891"` | `true` | `true` | **PASS** |
| **TC_MOD1_02** | Module 1 | Validate positive claim amount within policy coverage bounds | Amount: \$15,000, Coverage: \$50,000 | `valid: true` | `valid: true` | **PASS** |
| **TC_MOD1_03** | Module 1 | Validate file upload MIME type whitelist (accept PDF/PNG/JPEG, reject EXE) | `"application/pdf"`, `"application/x-msdownload"` | `true` (PDF), `false` (EXE) | `true`, `false` | **PASS** |
| **TC_MOD1_04** | Module 1 | Validate document review status transitions | `PENDING` $\rightarrow$ `VERIFIED` | `true` | `true` | **PASS** |
| **TC_MOD1_05** | Module 1 | **[DEFECT 1]** Reject claim when claim amount exceeds policy coverage limit | Amount: \$60,000, Coverage: \$50,000 | `valid: false` | `valid: true` | **FAIL** |
| **TC_MOD2_01** | Module 2 | Validate Inception Velocity heuristic fires (+22 pts) for early loss hazard | Incident within 14 days of policy start | Triggered (+22 pts) | Triggered (+22 pts) | **PASS** |
| **TC_MOD2_02** | Module 2 | Validate Coverage Exhaustion heuristic fires (+25 pts) for $\ge 85\%$ ratio | Claim \$45k on \$50k policy (90%) | Triggered (+25 pts) | Triggered (+25 pts) | **PASS** |
| **TC_MOD2_03** | Module 2 | Validate Prior Fraud History penalty fires (+25 pts) for repeat offender | Past claim with `REJECTED` status | Triggered (+25 pts) | Triggered (+25 pts) | **PASS** |
| **TC_MOD2_04** | Module 2 | Validate low-exposure legitimate claim evaluates to `LOW` risk tier | \$1,200 claim, mature policy, full docs | `risk_level: 'LOW'` | `risk_level: 'LOW'` | **PASS** |
| **TC_MOD2_05** | Module 2 | **[DEFECT 2]** Validate claims scoring $\ge 65\%$ are assigned `HIGH` risk tier | Score 78% (90% ratio + early velocity) | `risk_level: 'HIGH'` | `risk_level: 'MEDIUM'` | **FAIL** |

---

## 2. Injected Code Defects (Explaining the 2 Failures)

As required by the lab prompt, two intentional defects were introduced into the business logic:

### Defect 1 (Module 1 - Claim Coverage Boundary Bug):
- **File:** `server/services/claimValidator.js` (Line 36)
- **Defective Code:**
  ```javascript
  if (amount > limit * 2.0) { // DEFECT: Allows claims up to 2x coverage limit!
    return { valid: false, error: 'Claim amount exceeds policy coverage limit' };
  }
  ```
- **Why `TC_MOD1_05` Fails:** A claim of \$60,000 against a \$50,000 policy limit should be rejected as invalid (`valid: false`). Because of the `* 2.0` operator bug, the validator erroneously reports `valid: true`.
- **How to Fix:** Change `amount > limit * 2.0` to `amount > limit`.

---

### Defect 2 (Module 2 - Fraud Severity Cutoff Threshold Bug):
- **File:** `server/services/fraudEngine.js` (Line 245)
- **Defective Code:**
  ```javascript
  if (finalScore >= 95) { // DEFECT: Cutoff raised from 65 to 95!
    riskLevel = "HIGH";
    recommendation = "FLAG_FOR_FRAUD_INVESTIGATION";
  } else if (finalScore >= 35) {
    riskLevel = "MEDIUM";
  }
  ```
- **Why `TC_MOD2_05` Fails:** An anomalous claim scores **78%** based on coverage exhaustion (+25 pts), inception velocity (+22 pts), and keyword red flags (+12 pts). According to the SRS, any claim scoring $\ge 65\%$ MUST be classified as `HIGH` severity. Because the cutoff was mistakenly raised to 95%, it is misclassified as `MEDIUM`.
- **How to Fix:** Change `if (finalScore >= 95)` back to `if (finalScore >= 65)`.

---

## 3. Real Terminal Test Execution Output

Run command:
```bash
cd server && npm test
```

Execution Output:
```
> insurance-claim-server@1.0.0 test
> node --test tests/*.test.js

▶ MODULE 1: Online Claim Submission & Document Management
  ✔ TC_MOD1_01 [PASS] - Should validate standard Claim ID format (CLM-YYYY-XXXX) (0.35ms)
  ✔ TC_MOD1_02 [PASS] - Should approve claim amount within policy coverage bounds (0.07ms)
  ✔ TC_MOD1_03 [PASS] - Should allow valid insurance evidence MIME types and reject executables (0.06ms)
  ✔ TC_MOD1_04 [PASS] - Should permit authorized document lifecycle status transitions (0.05ms)
  ✖ TC_MOD1_05 [FAIL] - Should reject claim when claim amount exceeds maximum policy coverage limit (0.68ms)
✖ MODULE 1: Online Claim Submission & Document Management (1.77ms)

▶ MODULE 2: Explainable Fraud Risk Analytics & Adjudication Workflow
  ✔ TC_MOD2_01 [PASS] - Should trigger RULE_INCEPTION_VELOCITY when incident occurs shortly after policy purchase (1.14ms)
  ✔ TC_MOD2_02 [PASS] - Should trigger RULE_COVERAGE_EXHAUSTION when claim utilizes >= 85% of max policy coverage (9.15ms)
  ✔ TC_MOD2_03 [PASS] - Should detect prior fraudulent or rejected claim history on claimant record (0.09ms)
  ✔ TC_MOD2_04 [PASS] - Should classify legitimate low-exposure claim as LOW risk tier (0.38ms)
  ✖ TC_MOD2_05 [FAIL] - Should classify high-risk claims (score >= 65%) into HIGH severity tier for SIU review (0.47ms)
✖ MODULE 2: Explainable Fraud Risk Analytics & Adjudication Workflow (11.83ms)

ℹ tests 10
ℹ suites 2
ℹ pass 8
ℹ fail 2
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 59.34ms
```

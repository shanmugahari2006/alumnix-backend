# 🔄 AlumniConnect: Complete Project Workflow

This document breaks down exactly how data flows through the Alumnix platform from the perspective of the users. You can use this guide to explain the user journey to the hackathon judges.

---

## 1. 🚪 User Onboarding & Authentication Workflow

The registration process is highly secure and ensures that only verified individuals can join the network.

1. **Identity Verification:**
   - A user selects their role (`Student`, `Alumni`, or `Faculty`) and enters their University ID (USN/Employee ID).
   - The backend checks the pre-loaded university database (`CollegeRecord`) to verify this person actually belongs to the college.
2. **OTP Verification:**
   - Once verified, the backend sends a 6-digit OTP to the user's registered email or phone number.
   - The user enters the OTP to prove they own the contact method.
3. **Account Creation:**
   - The user sets a password (which is heavily encrypted using `bcrypt`).
   - The account is created.
4. **Admin Approval (For Alumni & Faculty):**
   - Students are granted immediate access.
   - Alumni and Faculty are placed into a **Pending State**. They cannot interact with the platform until a `System Administrator` reviews their details and clicks **Approve** in the Admin Dashboard.
5. **Login:**
   - Users log in with their email/phone and password. The backend issues a secure **JWT (JSON Web Token)** that acts as their digital ID card for all future requests.

---

## 2. 👥 Role-Based User Journeys

The platform adapts its features based on who is logged in.

### 🎓 The Student Journey
* **Goal:** Networking, Mentorship, and Career Growth.
* **Workflow:**
  - **Career Board:** Students browse jobs posted by Alumni. They can click "Apply", submit a link to their resume, and the application is routed directly to the Alumnus who posted it.
  - **Mentorship:** Students search the Alumni Directory (filtering by skills/companies) and can initiate direct **Messages** or request **1-on-1 Video Meetings** (powered by Jitsi).
  - **Events:** Students RSVP for upcoming college events and webinars.

### 💼 The Alumni Journey
* **Goal:** Giving back, Hiring, and Reconnecting.
* **Workflow:**
  - **Career Board:** Alumni click "Post a Job". They fill out the title, company, and description. They can then view a list of all students who applied to their specific posting.
  - **Fundraising:** Alumni can browse verified college fundraisers (e.g., "New Library Computers") and make secure monetary donations via the **Razorpay Payment Gateway**.
  - **Success Stories:** Alumni post updates about their career achievements, which students and other alumni can read and "Like".

### 🏫 The Faculty Journey
* **Goal:** Platform moderation and tracking student success.
* **Workflow:**
  - Faculty members act as trusted community voices. They can post Success Stories highlighting student achievements, announce Events (like hackathons or seminars), and mentor students through the chat system.

### 🛡️ The Admin Journey
* **Goal:** Platform security and data management.
* **Workflow:**
  - **Admin Review:** Admins monitor a live queue of newly registered Alumni and Faculty. They verify credentials and approve them to enter the active community.
  - **Analytics:** Admins view top-level statistics (total users, total funds raised, active jobs) to track platform health.

---

## 3. ⚙️ Core Feature Workflows (How the systems work)

### 💳 Secure Donations (Razorpay)
1. **Initiation:** An Alumnus enters a donation amount (e.g., ₹1000) and clicks Donate.
2. **Order Creation:** The backend securely contacts Razorpay's servers to create an `order_id` and sends it to the frontend.
3. **Transaction:** The Razorpay popup appears. The user completes the payment via UPI, Card, or Netbanking.
4. **Verification (Crucial for Hackathons):** Razorpay sends a payment signature back to the frontend, which forwards it to the backend. Our backend uses a secret key to perform a cryptographic check (HMAC-SHA256) on the signature. If it matches, the database is updated to reflect the new donation.

### 📹 Video Mentorship (Jitsi SDK)
1. When a meeting is scheduled, the backend generates a unique, secure Room ID.
2. At the scheduled time, both the Student and Alumni click "Join Meeting".
3. The React frontend uses the `@jitsi/react-sdk` to embed a high-quality, open-source video conferencing interface directly inside the web browser—no external app downloads required.

### 💬 Real-Time Messaging
1. Users search for a person in the directory and click "Message".
2. The backend creates a unique `Conversation` thread between the two users.
3. As users type and send messages, the backend saves them to the database and tracks `unread_count` for the recipient. 

### 🗂️ Job Applications
1. An Alumnus posts a job. It is saved in the `Jobs` table, linked to their specific UUID as the `creator_id`.
2. A Student applies. The backend creates a record in the `JobApplications` table linking the `student_id`, the `job_id`, and their `resume_url`.
3. When the Alumnus checks their dashboard, the backend queries the database for all `JobApplications` where the `job_id` belongs to them, presenting them with a list of candidates.

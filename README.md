# 📋 Job Application Tracker on Blockchain

A decentralized job application tracking system built on the Stacks blockchain using Clarity smart contracts. Track your job applications, manage application statuses, and maintain a comprehensive employment search history on-chain.

## 🚀 Features

- **📝 Application Management**: Submit and track job applications with detailed information
- **🏢 Employer Registry**: Register employers with verification system
- **📊 Status Tracking**: Monitor application progress through multiple stages
- **📜 Application History**: Maintain immutable record of status changes
- **📈 Analytics**: View application summaries and statistics
- **🔒 Secure**: Decentralized storage with user ownership of data

## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/Job-Application-Tracker-on-Blockchain.git
   cd Job-Application-Tracker-on-Blockchain
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Deploy the contract**
   ```bash
   clarinet deploy --testnet
   ```

## 💻 Usage

### 🏢 Employer Management

**Register a new employer:**
```clarity
(contract-call? .job-application-tracker register-employer 
  "TechCorp Inc" 
  "Technology" 
  "Medium" 
  "San Francisco, CA" 
  "https://techcorp.com")
```

**Verify employer (owner only):**
```clarity
(contract-call? .job-application-tracker verify-employer u1)
```

### 📋 Application Management

**Submit a job application:**
```clarity
(contract-call? .job-application-tracker submit-application
  u1                              ;; employer-id
  "Senior Developer"              ;; position-title
  "TechCorp Inc"                 ;; company-name
  "Applied through LinkedIn"      ;; notes
  u120000                        ;; salary-range
  "San Francisco, CA"            ;; location
  "Online Portal"                ;; application-method
  "John Smith")                  ;; contact-person
```

**Update application status:**
```clarity
(contract-call? .job-application-tracker update-application-status
  u1                             ;; application-id
  "interview-scheduled"          ;; new-status
  "Interview scheduled for next week")  ;; notes
```

**Update application notes:**
```clarity
(contract-call? .job-application-tracker update-application-notes
  u1                             ;; application-id
  "Updated salary expectations")  ;; new-notes
```

### 📊 Data Retrieval

**Get application details:**
```clarity
(contract-call? .job-application-tracker get-application u1)
```

**Get user's applications:**
```clarity
(contract-call? .job-application-tracker get-user-applications 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECWST890)
```

**Get applications summary:**
```clarity
(contract-call? .job-application-tracker get-applications-summary 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECWST890)
```

## 📋 Application Statuses

The contract supports the following application statuses:

- 📝 `submitted` - Application submitted
- 👀 `under-review` - Under review by employer
- 📅 `interview-scheduled` - Interview scheduled
- 🤝 `interviewed` - Interview completed
- 💰 `offer-received` - Job offer received
- ✅ `accepted` - Offer accepted
- ❌ `rejected` - Application rejected
- 🚫 `withdrawn` - Application withdrawn

## 🏗️ Contract Structure

### Data Maps

- **`applications`**: Stores application details
- **`employers`**: Registry of employers
- **`user-applications`**: Maps users to their applications
- **`employer-applications`**: Maps employers to applications
- **`application-history`**: Tracks status change history

### Key Functions

#### Public Functions
- `register-employer`: Register a new employer
- `verify-employer`: Verify employer (owner only)
- `submit-application`: Submit new job application
- `update-application-status`: Update application status
- `update-application-notes`: Update application notes
- `delete-application`: Delete application
- `bulk-update-status`: Update multiple applications

#### Read-Only Functions
- `get-application`: Get application by ID
- `get-employer`: Get employer by ID
- `get-user-applications`: Get user's applications
- `get-employer-applications`: Get employer's applications
- `get-applications-summary`: Get application statistics
- `get-application-count`: Get total applications
- `get-employer-count`: Get total employers

## 🧪 Testing

Run the test suite:
```bash
npm test
```

Check contract syntax:
```bash
clarinet check
```

## 🔧 Development

### Requirements
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js v14+
- TypeScript

### Local Development
```bash
clarinet console
```

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📞 Support

- 📧 Email: support@example.com
- 💬 Discord: [Join our community](https://discord.gg/example)
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/Job-Application-Tracker-on-Blockchain/issues)

---

Built with ❤️ on the Stacks blockchain

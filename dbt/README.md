## Development Setup

1. Create Python Virtual Environment

   ```bash
   python -m venv .venv
   ```

2. Activate Virtual Environment

   * **Windows:**

     ```bash
     .venv\Scripts\activate
     ```
   * **macOS/Linux:**

     ```bash
     source .venv/bin/activate
     ```

3. Install Requirements

   ```bash
   pip install -r requirements.txt
   ```

4. Install DBT Dependencies

   ```bash
   dbt deps
   ```

5. Verify Database Credentials
   Ensure your connection details are correctly set in the `profiles.yml` file.

6. Validate Source Database
   Make sure the source database and all required tables are available in your local PostgreSQL instance.

7. Run DBT

   * To run all models:

     ```bash
     dbt run
     ```
   * To run a specific model:

     ```bash
     dbt run --select "models/hr/employee.sql"
     ```

---

## Tools

### VS Code Extension

Enhance your DBT workflow with the **DBT Power User** extension:
[https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user](https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user)

---

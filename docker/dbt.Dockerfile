# 1️⃣ Base Python image (lightweight)
FROM python:3.11-slim

# 2️⃣ Set folder inside container where code will live
WORKDIR /app

# 3️⃣ Install dbt (you don’t need requirements.txt)
RUN pip install --no-cache-dir dbt-core~=1.7.11 dbt-postgres~=1.7.11

# 4️⃣ Copy your local dbt code into the image
COPY dbt/ /app

# 5️⃣ Install dbt dependencies
RUN dbt deps

# 6️⃣ Tell dbt where to find profiles.yml (if inside project)
ENV DBT_PROFILES_DIR=/app

# 7️⃣ Default command when container runs
ENTRYPOINT ["dbt"]




# docker build -t dbt-local:latest .
# Verify : docker images
# kind load docker-image dbt-local:latest --name airflow-airbyte
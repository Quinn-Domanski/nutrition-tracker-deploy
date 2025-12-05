FROM python:3.12-alpine
WORKDIR /app

RUN apk add --no-cache curl gcc musl-dev postgresql-dev linux-headers

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", \
     "-w", "4", \
     "-b", "0.0.0.0:5000", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "--worker-class", "sync", \
     "app:app"]
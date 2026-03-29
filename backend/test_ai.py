import requests
try:
    print("Sending request...")
    resp = requests.post("http://127.0.0.1:8000/tasks/ai/generate", json={"prompt": "plan a party"}, timeout=10)
    print("Status code:", resp.status_code)
    print("Response:", resp.text)
except Exception as e:
    print("Error:", e)

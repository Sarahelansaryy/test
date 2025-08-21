from app.main import app

def test_index():
    client = app.test_client()
    r = client.get('/')
    assert r.status_code == 200
    assert 'Hello from Flask CI/CD!' in r.get_data(as_text=True)

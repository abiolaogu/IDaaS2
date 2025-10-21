# This is a simulated end-to-end test. It does not perform a full browser-based
# login flow, but it does verify that the web application correctly handles
# the headers that would be passed by the authentication proxy.
import requests
import pytest

# For this test to run, the web application must be running.
# In a real CI/CD pipeline, you would start the application in a background process
# before running the tests.

BASE_URL = "http://localhost:8080" # Assuming the app is running locally for the test

def test_unauthenticated_access():
    """
    Simulates a request from an unauthenticated user.
    OAuth2-Proxy would not forward any identity headers.
    """
    response = requests.get(BASE_URL)
    assert response.status_code == 200
    assert "Hello, stranger! You are not authenticated." in response.text

def test_authenticated_access():
    """
    Simulates a request from an authenticated user.
    OAuth2-Proxy would add the X-Forwarded-Email header after a successful login.
    """
    headers = {"X-Forwarded-Email": "test@example.com"}
    response = requests.get(BASE_URL, headers=headers)
    assert response.status_code == 200
    assert "Hello, test@example.com! You are authenticated." in response.text

if __name__ == "__main__":
    pytest.main()

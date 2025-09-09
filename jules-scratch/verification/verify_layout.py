from playwright.sync_api import sync_playwright

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto("http://localhost:5173/projects")
        page.wait_for_load_state("networkidle") # Wait for the page to be fully loaded
        page.screenshot(path="/app/jules-scratch/verification/projects_page_view.png")
        browser.close()

if __name__ == "__main__":
    run()

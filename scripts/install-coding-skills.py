"""Run the bundled skill installer with Python runtimes using an isolated path."""

from pathlib import Path
import runpy
import sys
import tempfile

INSTALLER_DIR = Path(r"C:\Users\User\.codex\skills\.system\skill-installer\scripts")
SKILLS = {
    "flutter/agent-plugins": [
        "flutter-apply-architecture-best-practices",
        "flutter-build-responsive-layout",
        "flutter-fix-layout-issues",
        "flutter-add-widget-test",
        "flutter-implement-json-serialization",
        "flutter-setup-localization",
        "flutter-use-http-package",
    ],
    "dart-lang/skills": [
        "dart-add-unit-test",
        "dart-run-static-analysis",
        "dart-resolve-package-conflicts",
        "dart-use-path-package",
    ],
}

sys.path.insert(0, str(INSTALLER_DIR))
import github_utils

source_directory = Path(tempfile.gettempdir()) / "arta-skill-sources"

for repo, names in SKILLS.items():
    def read_downloaded_archive(url: str, user_agent: str) -> bytes:
        expected_url = f"https://codeload.github.com/{repo}/zip/main"
        if url != expected_url:
            raise ValueError(f"Unexpected skill source URL: {url}")
        return (source_directory / (repo.replace("/", "-") + ".zip")).read_bytes()

    # Windows HTTPS downloads the archives first; keep the bundled installer's
    # path validation, safe extraction, skill checks, and destination handling.
    github_utils.github_request = read_downloaded_archive
    sys.argv = [
        str(INSTALLER_DIR / "install-skill-from-github.py"),
        "--repo", repo,
        "--path", *[f"skills/{name}" for name in names],
        "--method", "download",
    ]
    try:
        runpy.run_path(sys.argv[0], run_name="__main__")
    except SystemExit as error:
        if error.code not in (None, 0):
            raise

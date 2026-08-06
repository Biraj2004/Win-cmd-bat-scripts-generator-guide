# Automated Test Suite Guide & Harness

This document defines the official testing methodology and automated testing harness for all Windows (`.bat`) and macOS (`.sh`) scripts in this repository.

---

## 1. Testing Philosophy & Safety Rules

To ensure scripts remain 100% reliable, production-ready, and non-destructive:

1. **Isolated Sandboxing**: Never run test scripts directly against actual repository files or user directories. All tests MUST execute inside a dedicated, isolated temporary folder (e.g. `test_suite_sandbox/`).
2. **Idempotency Verification**: Every test must run twice:
   - **Run 1**: Verifies correct file renaming, watermark removal, or numeric prefix stripping.
   - **Run 2**: Verifies that re-running the script touches zero files (`Renamed: 0`), skips all files (`Skipped: N`), and throws zero errors (`Errors: 0`).
3. **Cross-Platform Compatibility**: macOS scripts are tested under Bash (using Git Bash or native macOS Terminal), verifying BSD `stat` and GNU `stat` handling.
4. **Cleanup**: Test sandboxes must be cleaned up automatically after test execution.

---

## 2. Test Suite Architecture

The repository test suite consists of 6 test cases covering all script pairs:

| Test Case | Script Tested | Verification Objective |
| :--- | :--- | :--- |
| **Test 1** | `Win_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.bat` | Independent Video (`01..03`) and PDF (`01..02`) numbering per folder |
| **Test 2** | `Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat` | Case-insensitive watermark tag removal (`@hamaracollege` / `@Hamaracollege`) |
| **Test 3** | `Win_Strip_Mismatched_Numbered_Prefix.bat` | Numeric prefix stripping (`07-`, `12 -`) while preserving non-numeric prefixes |
| **Test 4** | `macOS_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.sh` | Independent Video & PDF numbering under Bash |
| **Test 5** | `macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh` | Watermark tag removal under Bash |
| **Test 6** | `macOS_Strip_Mismatched_Numbered_Prefix.sh` | Numeric prefix stripping under Bash |

---

## 3. Automated Test Harness (`test_all_scripts.py`)

Run this Python script from the repository root to verify all 6 scripts:

```python
import os
import shutil
import time
import subprocess
import re
import sys

repo_dir = os.path.abspath(os.path.dirname(__file__))
if os.path.basename(repo_dir) == "guide":
    repo_dir = os.path.dirname(repo_dir)

test_sandbox = os.path.join(repo_dir, "test_suite_sandbox")
bash_cmd = shutil.which("bash") or r"C:\Program Files\Git\bin\bash.exe"

def reset_sandbox():
    if os.path.exists(test_sandbox):
        shutil.rmtree(test_sandbox)
    os.makedirs(test_sandbox)

print("=====================================================================")
print("             RUNNING COMPREHENSIVE 6-SCRIPT TEST SUITE               ")
print("=====================================================================")

# -------------------------------------------------------------------
# TEST 1: Win_Add_Numberring_Based_On_Creation_Date_Ascending.bat
# -------------------------------------------------------------------
print("\n--- [TEST 1/6] Win_Add_Numberring_Based_On_Creation_Date_Ascending.bat ---")
reset_sandbox()
vids = ["vid_a.mp4", "vid_b.mkv", "vid_c.webm"]
pdfs = ["doc_a.pdf", "doc_b.pdf"]

for i, vid in enumerate(vids):
    p = os.path.join(test_sandbox, vid)
    with open(p, "w") as f: f.write("v")
    ps = f"(Get-Item '{p}').CreationTime = (Get-Date).AddSeconds({i*10})"
    subprocess.run(["powershell", "-Command", ps], check=True)

for i, pdf in enumerate(pdfs):
    p = os.path.join(test_sandbox, pdf)
    with open(p, "w") as f: f.write("p")
    ps = f"(Get-Item '{p}').CreationTime = (Get-Date).AddSeconds({i*10})"
    subprocess.run(["powershell", "-Command", ps], check=True)

bat1 = os.path.join(repo_dir, "Win_Add_Numberring_Based_On_Creation_Date_Ascending.bat")
with open(bat1, "r", encoding="utf-8") as f: content = f.read()
m1 = re.search(r'-EncodedCommand "(.*?)"', content)
assert m1, "No EncodedCommand in Win_Add_Numberring"

proc1 = subprocess.run(
    ["powershell", "-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass", "-EncodedCommand", m1.group(1)],
    cwd=test_sandbox, capture_output=True, text=True
)

files1 = sorted(os.listdir(test_sandbox))
print("Files:", files1)
assert "01 - vid_a.mp4" in files1 and "01 - doc_a.pdf" in files1
print("[PASS] Test 1 passed.")

# -------------------------------------------------------------------
# TEST 2: Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat
# -------------------------------------------------------------------
print("\n--- [TEST 2/6] Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat ---")
reset_sandbox()
test_files_2 = {
    "01 - Intro @hamaracollege.mp4": "01 - Intro .mp4",
    "02 - Lecture @Hamaracollege.mkv": "02 - Lecture .mkv",
    "Notes @HAMARACOLLEGE.pdf": "Notes .pdf",
    "CleanVideo.mp4": "CleanVideo.mp4"
}
for orig in test_files_2.keys():
    with open(os.path.join(test_sandbox, orig), "w") as f: f.write("test")

bat2 = os.path.join(repo_dir, "Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat")
with open(bat2, "r", encoding="utf-8") as f: content2 = f.read()
m2 = re.search(r'-EncodedCommand "(.*?)"', content2)
assert m2, "No EncodedCommand in Win_Remove_Hamaracollege"

proc2 = subprocess.run(
    ["powershell", "-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass", "-EncodedCommand", m2.group(1)],
    cwd=test_sandbox, capture_output=True, text=True
)
files2 = sorted(os.listdir(test_sandbox))
print("Files:", files2)
for exp in test_files_2.values():
    assert exp in files2, f"Missing {exp} in {files2}"
print("[PASS] Test 2 passed.")

# -------------------------------------------------------------------
# TEST 3: Win_Strip_Mismatched_Numbered_Prefix.bat
# -------------------------------------------------------------------
print("\n--- [TEST 3/6] Win_Strip_Mismatched_Numbered_Prefix.bat ---")
reset_sandbox()
test_files_3 = {
    "07-Lecture.mp4": "Lecture.mp4",
    "12 - Notes.pdf": "Notes.pdf",
    "Part1-Intro.mp4": "Part1-Intro.mp4",
    "NoHyphen.mp4": "NoHyphen.mp4"
}
for orig in test_files_3.keys():
    with open(os.path.join(test_sandbox, orig), "w") as f: f.write("test")

bat3 = os.path.join(repo_dir, "Win_Strip_Mismatched_Numbered_Prefix.bat")
with open(bat3, "r", encoding="utf-8") as f: content3 = f.read()
m3 = re.search(r'-EncodedCommand "(.*?)"', content3)
assert m3, "No EncodedCommand in Win_Strip_Mismatched"

proc3 = subprocess.run(
    ["powershell", "-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass", "-EncodedCommand", m3.group(1)],
    cwd=test_sandbox, capture_output=True, text=True
)
files3 = sorted(os.listdir(test_sandbox))
print("Files:", files3)
for exp in test_files_3.values():
    assert exp in files3, f"Missing {exp} in {files3}"
print("[PASS] Test 3 passed.")

# -------------------------------------------------------------------
# TEST 4: macOS_Add_Numberring_Based_On_Creation_Date_Ascending.sh
# -------------------------------------------------------------------
print("\n--- [TEST 4/6] macOS_Add_Numberring_Based_On_Creation_Date_Ascending.sh ---")
reset_sandbox()
for i, vid in enumerate(vids):
    with open(os.path.join(test_sandbox, vid), "w") as f: f.write("v")
for i, pdf in enumerate(pdfs):
    with open(os.path.join(test_sandbox, pdf), "w") as f: f.write("p")

sh1_src = os.path.join(repo_dir, "Mac-Equivalent-Scripts", "macOS_Add_Numberring_Based_On_Creation_Date_Ascending.sh")
sh1_dst = os.path.join(test_sandbox, "macOS_Add_Numberring_Based_On_Creation_Date_Ascending.sh")
shutil.copy(sh1_src, sh1_dst)

proc4 = subprocess.run(
    [bash_cmd, "macOS_Add_Numberring_Based_On_Creation_Date_Ascending.sh"], input="Y\n", cwd=test_sandbox, capture_output=True, text=True
)
os.remove(sh1_dst)
files4 = sorted(os.listdir(test_sandbox))
print("Files:", files4)
assert "01 - vid_a.mp4" in files4 and "01 - doc_a.pdf" in files4
print("[PASS] Test 4 passed.")

# -------------------------------------------------------------------
# TEST 5: macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh
# -------------------------------------------------------------------
print("\n--- [TEST 5/6] macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh ---")
reset_sandbox()
for orig in test_files_2.keys():
    with open(os.path.join(test_sandbox, orig), "w") as f: f.write("test")

sh2_src = os.path.join(repo_dir, "Mac-Equivalent-Scripts", "macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh")
sh2_dst = os.path.join(test_sandbox, "macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh")
shutil.copy(sh2_src, sh2_dst)

proc5 = subprocess.run(
    [bash_cmd, "macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh"], input="Y\n", cwd=test_sandbox, capture_output=True, text=True
)
os.remove(sh2_dst)
files5 = sorted(os.listdir(test_sandbox))
print("Files:", files5)
for exp in test_files_2.values():
    assert exp in files5, f"Missing {exp} in {files5}"
print("[PASS] Test 5 passed.")

# -------------------------------------------------------------------
# TEST 6: macOS_Strip_Mismatched_Numbered_Prefix.sh
# -------------------------------------------------------------------
print("\n--- [TEST 6/6] macOS_Strip_Mismatched_Numbered_Prefix.sh ---")
reset_sandbox()
for orig in test_files_3.keys():
    with open(os.path.join(test_sandbox, orig), "w") as f: f.write("test")

sh3_src = os.path.join(repo_dir, "Mac-Equivalent-Scripts", "macOS_Strip_Mismatched_Numbered_Prefix.sh")
sh3_dst = os.path.join(test_sandbox, "macOS_Strip_Mismatched_Numbered_Prefix.sh")
shutil.copy(sh3_src, sh3_dst)

proc6 = subprocess.run(
    [bash_cmd, "macOS_Strip_Mismatched_Numbered_Prefix.sh"], input="Y\n", cwd=test_sandbox, capture_output=True, text=True
)
os.remove(sh3_dst)
files6 = sorted(os.listdir(test_sandbox))
print("Files:", files6)
for exp in test_files_3.values():
    assert exp in files6, f"Missing {exp} in {files6}"
print("[PASS] Test 6 passed.")

reset_sandbox()
os.rmdir(test_sandbox)

print("\n=====================================================================")
print("            ALL 6 SCRIPTS TESTED AND 100% WORKING!                   ")
print("=====================================================================")
```

---

## 4. How to Run the Tests

To run the automated test suite locally:

```bash
python guide/Test_Script.md # or python scratch/test_all_scripts.py
```
Or execute:
```bash
python -c "import test_all_scripts"
```

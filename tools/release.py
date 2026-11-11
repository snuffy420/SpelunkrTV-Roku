"""Build the Roku ZIP and a genuine 7z source archive, both with SHA-256 checksums."""
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import package  # noqa: E402

root = Path(__file__).resolve().parents[1]
package.main()

sevenzip = shutil.which("7z") or shutil.which("7zz")
if not sevenzip:
    candidate = Path("C:/Program Files/7-Zip/7z.exe")
    if candidate.is_file():
        sevenzip = str(candidate)
if not sevenzip:
    raise SystemExit("Install 7-Zip and place 7z on PATH to build the source archive.")

output = root / f"releases/spelunkr-tv-guide-v{package.version()}-source.7z"
excluded = {"releases", ".git", "__pycache__", "node_modules", ".staging", "out"}
files = [p.relative_to(root).as_posix() for p in sorted(root.rglob("*"))
         if p.is_file() and not set(p.relative_to(root).parts) & excluded
         and p.suffix not in {".pyc", ".log"}]
# Remove only this exact generated archive before rebuilding; never update an old archive in place.
output.unlink(missing_ok=True)
listing = root / "releases/source-files.lst"
try:
    listing.write_text("\n".join(files) + "\n", encoding="utf-8")
    subprocess.run([sevenzip, "a", "-t7z", "-mx=7", "-scsUTF-8", str(output), "@" + str(listing)],
                   cwd=root, check=True, stdout=subprocess.DEVNULL)
finally:
    listing.unlink(missing_ok=True)
subprocess.run([sevenzip, "t", str(output)], check=True, stdout=subprocess.DEVNULL)
assert output.read_bytes()[:6] == b"7z\xbc\xaf\x27\x1c"
digest = package.write_checksum(str(output))
print(f"{output}\nSHA256 {digest}")

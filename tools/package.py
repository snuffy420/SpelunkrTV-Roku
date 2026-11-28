"""Builds the sideload zip. Only files the Roku uses go in the package."""
import hashlib
import os
import re
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXCLUDED_IMAGES = (".svg", ".gif")


def version():
    manifest = open(os.path.join(ROOT, "manifest"), encoding="utf-8").read()
    major = re.search(r"major_version=(\d+)", manifest).group(1)
    minor = re.search(r"minor_version=(\d+)", manifest).group(1)
    build = re.search(r"build_version=(\d+)", manifest)
    patch = int(build.group(1)) if build else 0
    # Keep the established 1.x names (1.0 rather than 1.0.0), and use the
    # full semantic version for the 2.0 major release and later.
    if patch > 0 or int(major) >= 2:
        return f"{major}.{minor}.{patch}"
    return f"{major}.{minor}"


def package_files():
    yield "manifest"
    for folder in ("source", "components", "images"):
        for directory, _, names in sorted(os.walk(os.path.join(ROOT, folder))):
            for name in sorted(names):
                if not name.lower().endswith(EXCLUDED_IMAGES):
                    yield os.path.relpath(os.path.join(directory, name), ROOT).replace(os.sep, "/")


def write_checksum(path):
    digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
    with open(path + ".sha256", "w", encoding="ascii", newline="\n") as sidecar:
        sidecar.write(f"{digest}  {os.path.basename(path)}\n")
    return digest


def main():
    os.makedirs(os.path.join(ROOT, "releases"), exist_ok=True)
    output = os.path.join(ROOT, "releases", f"spelunkr-tv-guide-v{version()}-roku.zip")
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in package_files():
            archive.write(os.path.join(ROOT, path), path)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
    digest = write_checksum(output)
    print(output, os.path.getsize(output), "bytes")
    print("SHA256", digest)
    return output


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

"""
Download all LHAPDF tarballs whose set names start with a given prefix.

Examples:
    # Download into the directory containing this script
    python downloadpdfs.py EPPS21

    # Download into a custom directory
    python downloadpdfs.py EPPS21 --output-dir /path/to/dir

This will fetch `https://lhapdf.hepforge.org/pdfsets.html`, find all
tarball links whose filenames start with "EPPS21", and download them
into the directory containing this script by default, or into the
specified output directory.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
import tarfile
from urllib.error import HTTPError, URLError
from urllib.request import urlopen


PDFSETS_PAGE_URL = "https://lhapdf.hepforge.org/pdfsets.html"
TARBALL_BASE_URL = "http://lhapdfsets.web.cern.ch/lhapdfsets/current/"


def fetch_pdfsets_page() -> str:
    with urlopen(PDFSETS_PAGE_URL) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(charset, errors="replace")


def find_tarballs(html: str, prefix: str) -> list[str]:
    """
    Return list of tarball filenames whose set name starts with prefix.

    We look for anchors that point to .../current/<name>.tar.gz where
    <name> starts with the prefix.
    """
    # Escape prefix to avoid regex metacharacters
    escaped_prefix = re.escape(prefix)
    pattern = re.compile(
        rf'href="http://lhapdfsets\.web\.cern\.ch/lhapdfsets/current/({escaped_prefix}[^"]+?\.tar\.gz)"'
    )
    return sorted({m.group(1) for m in pattern.finditer(html)})


def download_file(filename: str, dest_dir: Path) -> Path | None:
    url = f"{TARBALL_BASE_URL}{filename}"
    dest_path = dest_dir / filename
    extracted_dir = dest_dir / filename.removesuffix(".tar.gz")

    if dest_path.exists():
        print(f"Skip existing tarball: {dest_path}")
        return dest_path

    if extracted_dir.is_dir():
        print(f"Skip already-extracted set: {extracted_dir}")
        return None

    print(f"Downloading {url} -> {dest_path}")
    try:
        with urlopen(url) as resp, dest_path.open("wb") as out_f:
            while True:
                chunk = resp.read(8192)
                if not chunk:
                    break
                out_f.write(chunk)
        return dest_path
    except (HTTPError, URLError) as e:
        # Remove partial file, if any
        if dest_path.exists():
            try:
                dest_path.unlink()
            except OSError:
                pass
        print(f"Failed to download {url}: {e}", file=sys.stderr)
        return None


def unpack_and_remove(tar_path: Path, dest_dir: Path) -> None:
    """
    Unpack a .tar.gz into dest_dir and remove the tarball on success.
    """
    if not tarfile.is_tarfile(tar_path):
        print(f"Not a valid tar file, skipping: {tar_path}", file=sys.stderr)
        return

    print(f"Unpacking {tar_path} into {dest_dir}")
    try:
        with tarfile.open(tar_path, "r:gz") as tf:
            tf.extractall(path=dest_dir)
        tar_path.unlink()
    except Exception as e:
        print(f"Failed to unpack {tar_path}: {e}", file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    # Default destination directory is the directory containing this script
    script_dir = Path(__file__).resolve().parent

    parser = argparse.ArgumentParser(
        description=(
            "Download all LHAPDF tarballs from pdfsets.html whose names "
            "start with a given prefix (e.g. EPPS21)."
        )
    )
    parser.add_argument(
        "prefix",
        help="Set name prefix to match (e.g. EPPS21, EPPS16, CT18, NNPDF31)",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        type=Path,
        default=script_dir,
        help=(
            "Directory to store downloaded PDFs and extracted files "
            "(default: directory containing this script)"
        ),
    )
    args = parser.parse_args(argv)

    dest_dir = args.output_dir
    dest_dir.mkdir(parents=True, exist_ok=True)

    try:
        html = fetch_pdfsets_page()
    except (HTTPError, URLError) as e:
        print(f"Failed to fetch {PDFSETS_PAGE_URL}: {e}", file=sys.stderr)
        return 1

    tarballs = find_tarballs(html, args.prefix)
    if not tarballs:
        print(f"No tarballs found with prefix '{args.prefix}'", file=sys.stderr)
        return 1

    print(f"Found {len(tarballs)} tarball(s) with prefix '{args.prefix}'.")
    for fname in tarballs:
        tar_path = download_file(fname, dest_dir)
        if tar_path is not None:
            unpack_and_remove(tar_path, dest_dir)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())


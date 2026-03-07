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

from rich.console import Console
from rich.progress import (
    BarColumn,
    DownloadColumn,
    Progress,
    SpinnerColumn,
    TaskProgressColumn,
    TextColumn,
    TimeRemainingColumn,
    TransferSpeedColumn,
)
from rich.panel import Panel
from rich.text import Text

console = Console()

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
    escaped_prefix = re.escape(prefix)
    pattern = re.compile(
        rf'href="http://lhapdfsets\.web\.cern\.ch/lhapdfsets/current/({escaped_prefix}[^"]+?\.tar\.gz)"'
    )
    return sorted({m.group(1) for m in pattern.finditer(html)})


def download_file(filename: str, dest_dir: Path, progress: Progress, overall_task: int) -> Path | None:
    url = f"{TARBALL_BASE_URL}{filename}"
    dest_path = dest_dir / filename
    extracted_dir = dest_dir / filename.removesuffix(".tar.gz")

    if dest_path.exists():
        console.print(f"  [dim]⊘ Skip existing tarball:[/dim] [cyan]{filename}[/cyan]")
        progress.advance(overall_task)
        return dest_path

    if extracted_dir.is_dir():
        console.print(f"  [dim]⊘ Already extracted:[/dim] [cyan]{filename.removesuffix('.tar.gz')}[/cyan]")
        progress.advance(overall_task)
        return None

    try:
        with urlopen(url) as resp:
            total = int(resp.headers.get("Content-Length", 0)) or None
            dl_task = progress.add_task(f"[cyan]{filename}[/cyan]", total=total)
            try:
                with dest_path.open("wb") as out_f:
                    while True:
                        chunk = resp.read(65536)
                        if not chunk:
                            break
                        out_f.write(chunk)
                        progress.advance(dl_task, len(chunk))
            finally:
                progress.remove_task(dl_task)
        progress.advance(overall_task)
        return dest_path
    except (HTTPError, URLError) as e:
        if dest_path.exists():
            try:
                dest_path.unlink()
            except OSError:
                pass
        console.print(f"  [red bold]✗ Failed:[/red bold] [cyan]{filename}[/cyan] — {e}", highlight=False)
        progress.advance(overall_task)
        return None


def unpack_and_remove(tar_path: Path, dest_dir: Path) -> None:
    """Unpack a .tar.gz into dest_dir and remove the tarball on success."""
    if not tarfile.is_tarfile(tar_path):
        console.print(f"  [red bold]✗ Not a valid tar file:[/red bold] [cyan]{tar_path.name}[/cyan]")
        return

    with Progress(
        SpinnerColumn(),
        TextColumn("  [bold]Unpacking[/bold] [cyan]{task.description}[/cyan]"),
        console=console,
        transient=True,
    ) as unpack_progress:
        task = unpack_progress.add_task(tar_path.name, total=None)
        try:
            with tarfile.open(tar_path, "r:gz") as tf:
                tf.extractall(path=dest_dir)
            unpack_progress.update(task, completed=1, total=1)
        except Exception as e:
            console.print(f"  [red bold]✗ Failed to unpack[/red bold] [cyan]{tar_path.name}[/cyan]: {e}")
            return

    tar_path.unlink()
    console.print(f"  [green]✔ Extracted:[/green] [cyan]{tar_path.name.removesuffix('.tar.gz')}[/cyan]")


def main(argv: list[str] | None = None) -> int:
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

    console.print(Panel(
        Text.assemble(
            ("LHAPDF PDF Set Downloader", "bold white"),
            "\nPrefix: ",
            (args.prefix, "bold cyan"),
            "  →  ",
            (str(dest_dir), "dim"),
        ),
        border_style="blue",
        padding=(0, 1),
    ))

    with console.status("[bold blue]Fetching PDF set list…[/bold blue]", spinner="dots"):
        try:
            html = fetch_pdfsets_page()
        except (HTTPError, URLError) as e:
            console.print(f"[red bold]✗ Failed to fetch[/red bold] {PDFSETS_PAGE_URL}: {e}")
            return 1

    tarballs = find_tarballs(html, args.prefix)
    if not tarballs:
        console.print(f"[yellow]⚠ No tarballs found with prefix '[bold]{args.prefix}[/bold]'[/yellow]")
        return 1

    console.print(f"\n[green]Found [bold]{len(tarballs)}[/bold] tarball(s) matching '[bold]{args.prefix}[/bold]'[/green]\n")

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        DownloadColumn(),
        TransferSpeedColumn(),
        TimeRemainingColumn(),
        TaskProgressColumn(),
        console=console,
    ) as progress:
        overall = progress.add_task(
            f"[bold white]Overall ({len(tarballs)} sets)[/bold white]",
            total=len(tarballs),
        )
        for fname in tarballs:
            tar_path = download_file(fname, dest_dir, progress, overall)
            if tar_path is not None:
                unpack_and_remove(tar_path, dest_dir)

    console.print("\n[bold green]Done.[/bold green]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


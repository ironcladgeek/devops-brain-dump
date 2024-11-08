#!/usr/bin/env python

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Optional, Tuple

import markdown
import pdfkit
from tqdm import tqdm


class DocsToPDF:
    def __init__(self):
        """Initialize the converter with a temporary working directory."""
        self.temp_dir = tempfile.mkdtemp()
        self.repo_dir = None  # For storing cloned repository path

    def cleanup(self):
        """Clean up temporary directories."""
        if self.temp_dir and os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir, ignore_errors=True)
        if self.repo_dir and os.path.exists(self.repo_dir):
            shutil.rmtree(self.repo_dir, ignore_errors=True)

    @staticmethod
    def parse_github_url(url: str) -> Tuple[str, str, str, str]:
        """
        Parse GitHub URL to extract owner, repo, branch and path.

        Args:
            url: GitHub URL

        Returns:
            Tuple of (owner, repo, branch, path)
        """
        # Remove 'https://github.com/' from the start
        path = url.replace("https://github.com/", "")

        # Split the remaining path
        parts = path.split("/")

        owner = parts[0]
        repo = parts[1]

        # Find where the branch definition starts
        if "tree" in parts:
            tree_index = parts.index("tree")
            branch = parts[tree_index + 1]
            # Path is everything after the branch
            docs_path = "/".join(parts[tree_index + 2 :])
        else:
            # If no branch is specified, assume 'main' or 'master'
            branch = "main"
            docs_path = "/".join(parts[3:]) if len(parts) > 3 else ""

        return owner, repo, branch, docs_path

    def clone_repository(self, github_url: str) -> Tuple[str, str]:
        """
        Clone a GitHub repository to a temporary directory.

        Args:
            github_url: GitHub repository URL

        Returns:
            Tuple of (repository_path, docs_path)
        """
        try:
            owner, repo, branch, docs_path = self.parse_github_url(github_url)

            # Create temporary directory for the repository
            self.repo_dir = tempfile.mkdtemp()

            # Clone the repository
            print(f"Cloning repository {owner}/{repo}...")
            clone_url = f"https://github.com/{owner}/{repo}.git"
            subprocess.run(
                [
                    "git",
                    "clone",
                    "-b",
                    branch,
                    "--depth",
                    "1",
                    clone_url,
                    self.repo_dir,
                ],
                check=True,
                capture_output=True,
                text=True,
            )

            # Construct full docs path
            full_docs_path = os.path.join(self.repo_dir, docs_path)

            if not os.path.exists(full_docs_path):
                raise Exception(f"Documentation path not found: {docs_path}")

            return full_docs_path

        except subprocess.CalledProcessError as e:
            raise Exception(f"Failed to clone repository: {e.stderr}") from e
        except Exception as e:
            raise Exception(f"Error cloning repository: {str(e)}") from e

    def find_markdown_files(self, base_path: str) -> list:
        """
        Recursively find all markdown files in the given directory.
        Returns sorted list to maintain consistent ordering.
        """
        markdown_files = []
        base_path = Path(base_path)

        for file_path in sorted(base_path.rglob("*")):
            if file_path.suffix.lower() in [".md", ".markdown"]:
                rel_path = file_path.relative_to(base_path)
                markdown_files.append(
                    {
                        "path": str(file_path),
                        "rel_path": str(rel_path),
                        "name": file_path.name,
                        "anchor": f"doc_{len(markdown_files)}",
                    }
                )

        return markdown_files

    def read_markdown_content(self, markdown_files: list):
        """Read content from all markdown files."""
        for md_file in tqdm(
            markdown_files, total=len(markdown_files), desc="Reading files"
        ):
            try:
                with open(md_file["path"], "r", encoding="utf-8") as f:
                    md_file["content"] = f.read()
            except Exception as e:
                print(f"Error reading {md_file['path']}: {str(e)}")
                md_file["content"] = f"Error reading file: {str(e)}"

    def create_toc(self, markdown_files: list) -> str:
        """Create a table of contents in HTML with proper hierarchy."""
        toc = ["<h1>Table of Contents</h1>", '<ul class="toc">']

        current_dirs = []
        for md_file in tqdm(
            markdown_files, total=len(markdown_files), desc="Creating TOC"
        ):
            rel_path = Path(md_file["rel_path"])
            dirs = list(rel_path.parent.parts)

            while len(current_dirs) > 0 and (
                len(dirs) == 0 or current_dirs[0] != dirs[0]
            ):
                toc.append("</ul></li>")
                current_dirs.pop(0)

            while len(dirs) > 0 and (
                len(current_dirs) == 0 or current_dirs[0] != dirs[0]
            ):
                dir_name = dirs.pop(0)
                current_dirs.insert(0, dir_name)
                toc.append(f'<li class="dir">{dir_name}<ul>')

            file_name = rel_path.stem
            toc.append(
                f'<li class="file"><a href="#{md_file["anchor"]}">{file_name}</a></li>'
            )

        for _ in current_dirs:
            toc.append("</ul></li>")

        toc.append("</ul>")
        return "\n".join(toc)

    def convert_to_pdf(
        self, markdown_files: list, output_path: str, title: str = "Documentation"
    ):
        """Convert markdown files to a single PDF using pdfkit."""
        # HTML template
        html_template = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>{title}</title>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                    margin: 40px;
                    max-width: 900px;
                    margin: 0 auto;
                    padding: 20px;
                }}
                .toc {{
                    background-color: #f8f9fa;
                    padding: 20px;
                    border-radius: 5px;
                    margin-bottom: 30px;
                }}
                .toc .dir {{
                    font-weight: bold;
                    color: #333;
                    margin-top: 10px;
                }}
                .toc .file {{
                    margin-left: 10px;
                }}
                .toc a {{
                    color: #0366d6;
                    text-decoration: none;
                }}
                .toc a:hover {{
                    text-decoration: underline;
                }}
                pre {{
                    background-color: #f5f5f5;
                    padding: 15px;
                    border-radius: 5px;
                    overflow-x: auto;
                    font-size: 14px;
                    border: 1px solid #ddd;
                }}
                code {{
                    background-color: #f5f5f5;
                    padding: 2px 5px;
                    border-radius: 3px;
                    font-size: 14px;
                    border: 1px solid #ddd;
                }}
                table {{
                    border-collapse: collapse;
                    width: 100%;
                    margin: 15px 0;
                }}
                th, td {{
                    border: 1px solid #ddd;
                    padding: 8px;
                    text-align: left;
                }}
                th {{
                    background-color: #f5f5f5;
                }}
                img {{
                    max-width: 100%;
                    height: auto;
                }}
                h1 {{
                    border-bottom: 2px solid #333;
                    padding-bottom: 10px;
                }}
                h2 {{
                    margin-top: 30px;
                    border-bottom: 1px solid #ccc;
                    padding-bottom: 5px;
                }}
                .file-path {{
                    color: #666;
                    font-size: 0.9em;
                    margin-bottom: 10px;
                }}
                @media print {{
                    pre, code {{
                        white-space: pre-wrap;
                    }}
                    .toc {{
                        background-color: transparent;
                    }}
                }}
            </style>
        </head>
        <body>
            <h1>{title}</h1>
            {toc}
            {content}
        </body>
        </html>
        """

        # Read content from all files
        self.read_markdown_content(markdown_files)

        # Create table of contents
        toc_html = self.create_toc(markdown_files)

        # Convert markdown files to HTML
        html_contents = []
        for md_file in tqdm(
            markdown_files, total=len(markdown_files), desc="Converting to HTML"
        ):
            html = markdown.markdown(
                md_file["content"],
                extensions=[
                    "markdown.extensions.fenced_code",
                    "markdown.extensions.tables",
                    "markdown.extensions.toc",
                ],
            )
            html_contents.append(
                f'<div id="{md_file["anchor"]}" class="document">'
                f'<h2>{Path(md_file["rel_path"]).stem}</h2>'
                f'<div class="file-path">{md_file["rel_path"]}</div>'
                f'{html}</div>'
            )

        # Combine everything into a single HTML document
        html_content = html_template.format(
            title=title, toc=toc_html, content="\n".join(html_contents)
        )

        # Save HTML to temporary file
        temp_html = os.path.join(self.temp_dir, "output.html")
        with open(temp_html, "w", encoding="utf-8") as f:
            f.write(html_content)

        # PDF options
        options = {
            "page-size": "Letter",
            "margin-top": "20mm",
            "margin-right": "20mm",
            "margin-bottom": "20mm",
            "margin-left": "20mm",
            "encoding": "UTF-8",
            "no-outline": None,
            "enable-local-file-access": None,
        }

        try:
            print("Converting HTML to PDF...")
            pdfkit.from_file(temp_html, output_path, options=options)
        except OSError as e:
            if "wkhtmltopdf" in str(e):
                raise Exception(
                    "wkhtmltopdf is not installed. Please install it first:\n"
                    "- On Mac: brew install wkhtmltopdf\n"
                    "- On Linux: sudo apt-get install wkhtmltopdf\n"
                    "- Or download from: https://wkhtmltopdf.org/downloads.html"
                ) from e
            raise

    def convert(self, source: str, output_path: str, title: Optional[str] = None):
        """
        Convert documentation to PDF from either GitHub URL or local path.

        Args:
            source: GitHub URL or local path
            output_path: Output PDF file path
            title: Optional title for the documentation
        """
        try:
            # Determine if source is a GitHub URL or local path
            if source.startswith("https://github.com"):
                input_path = self.clone_repository(source)
                if title is None:
                    # Extract repo name from URL for title
                    owner, repo, _, _ = self.parse_github_url(source)
                    title = f"{repo} Documentation"
            else:
                input_path = os.path.abspath(source)
                if title is None:
                    title = (
                        os.path.basename(input_path.rstrip("/\\")) + " Documentation"
                    )

            print(f"Processing documentation in: {input_path}")

            if not os.path.exists(input_path):
                raise Exception(f"Input path does not exist: {input_path}")

            # Find all markdown files
            print("Finding markdown files...")
            markdown_files = self.find_markdown_files(input_path)

            if not markdown_files:
                raise Exception("No markdown files found in the specified path")

            # Convert to PDF
            print(f"Converting {len(markdown_files)} files to PDF...")
            self.convert_to_pdf(markdown_files, output_path, title)

            print(f"PDF successfully created at: {output_path}")

        except Exception as e:
            print(f"Error: {str(e)}")
            raise
        finally:
            self.cleanup()


def main():
    parser = argparse.ArgumentParser(
        description="Convert markdown documentation to PDF from GitHub repository or local folder."
    )
    parser.add_argument(
        "source",
        help="GitHub repository URL (https://github.com/user/repo/tree/branch/docs) or local folder path",
    )
    parser.add_argument("output", help="Output PDF file path")
    parser.add_argument("--title", help="Custom title for the documentation (optional)")

    args = parser.parse_args()

    try:
        converter = DocsToPDF()
        converter.convert(args.source, args.output, args.title)
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

# Docs to PDF Converter

A command-line tool to convert markdown documentation to PDF. Works with both local directories and GitHub repositories. The tool automatically generates a table of contents, preserves directory structure, and produces a well-formatted PDF document.

## Features

- Convert markdown files from local directories to PDF
- Convert markdown documentation directly from GitHub repositories
- Automatically generates table of contents with proper hierarchy
- Preserves directory structure in the table of contents
- Shows file paths for better navigation
- Supports code blocks with proper formatting
- Handles tables and images
- Creates bookmarked PDF for easy navigation
- Clean, professional styling with proper fonts and margins
- Progress bars for long operations
- Proper cleanup of temporary files

## Requirements

### System Dependencies

#### Mac OS
```bash
# Install wkhtmltopdf using Homebrew
brew install wkhtmltopdf

# Install git (if not already installed)
brew install git
```

#### Ubuntu/Debian
```bash
# Install wkhtmltopdf
sudo apt-get update
sudo apt-get install wkhtmltopdf

# Install git (if not already installed)
sudo apt-get install git
```

### Python Dependencies

The tool requires Python 3.6 or higher. Install the required Python packages:

```bash
pip install Markdown==3.7 pdfkit==1.0.0 tqdm==4.66.6
```

## Usage

### Basic Usage

The tool can be used in two ways: with a GitHub repository URL or with a local directory path.

#### Converting from GitHub Repository

```bash
python docs_to_pdf.py https://github.com/username/repo/tree/branch/docs output.pdf
```

Example:
```bash
python docs_to_pdf.py https://github.com/argoproj/argo-workflows/tree/main/docs argo-docs.pdf
```

#### Converting from Local Directory

```bash
python docs_to_pdf.py /path/to/docs output.pdf
```

Example:
```bash
python docs_to_pdf.py ./docs/markdown documentation.pdf
```

### Advanced Usage

#### Custom Title

You can specify a custom title for the documentation:

```bash
python docs_to_pdf.py source output.pdf --title "Custom Documentation Title"
```

### Command-line Arguments

```
usage: docs_to_pdf.py [-h] [--title TITLE] source output

Convert markdown documentation to PDF from GitHub repository or local folder.

positional arguments:
  source         GitHub repository URL (https://github.com/user/repo/tree/branch/docs) or local folder path
  output         Output PDF file path

optional arguments:
  -h, --help     show this help message and exit
  --title TITLE  Custom title for the documentation (optional)
```

## Output Format

The generated PDF includes:

1. Title page with the specified or auto-generated title
2. Table of contents with:
   - Directory hierarchy preserved
   - Clickable links to sections
   - Clear distinction between directories and files
3. Content pages with:
   - File paths for reference
   - Formatted code blocks
   - Tables
   - Images (if available locally)
   - Proper heading hierarchy

## Styling

The generated PDF includes the following styling features:

- Clean, readable font (Arial/sans-serif)
- Proper margins for readability
- Syntax highlighting for code blocks
- Background colors for better content distinction
- Responsive design for different paper sizes
- Clear heading hierarchy
- Proper spacing and indentation

## Limitations

1. Does not support authentication for private GitHub repositories
2. External images in markdown files may not be included
3. Some advanced markdown extensions may not be supported
4. PDF generation depends on wkhtmltopdf capabilities


## Acknowledgments

- [Python-Markdown](https://python-markdown.github.io/) for markdown processing
- [pdfkit](https://github.com/JazzCore/python-pdfkit) for PDF generation
- [wkhtmltopdf](https://wkhtmltopdf.org/) for HTML to PDF conversion
- [tqdm](https://github.com/tqdm/tqdm) for progress bars

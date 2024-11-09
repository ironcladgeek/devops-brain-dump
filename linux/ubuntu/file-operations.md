# 📂 File Operations Commands

Essential commands for file manipulation and management.

## Basic Operations

```bash
# Search for files
find /path/to/search -name "filename"
find . -type f -name "*.py"  # Find all Python files

# Search file contents
grep -r "search_text" /path/to/search
grep -i "case-insensitive" file.txt

# Create multiple directories
mkdir -p dir1/dir2/dir3

# Copy with progress
rsync -ah --progress source destination
```

## File Permissions

```bash
# Change ownership
chown user:group file
chown -R user:group directory  # Recursive

# Change permissions
chmod 755 file  # rwxr-xr-x
chmod -R 644 directory  # rw-r--r--

# Add execute permission
chmod +x script.sh
```

## File Compression

```bash
# Create tar archive
tar -czf archive.tar.gz /path/to/directory

# Extract tar archive
tar -xzf archive.tar.gz

# Zip directory
zip -r archive.zip directory/

# Unzip archive
unzip archive.zip
```

## File Transfer

```bash
# Secure copy between hosts
scp file.txt user@remote:/path/
scp -r directory/ user@remote:/path/

# Download from URL
wget https://example.com/file
curl -O https://example.com/file

# Sync directories
rsync -avz source/ destination/
```

## Text Processing

```bash
# View file content
cat file.txt
less file.txt
head -n 10 file.txt
tail -n 10 file.txt

# Count lines/words
wc -l file.txt  # Lines
wc -w file.txt  # Words

# Sort file content
sort file.txt
sort -n file.txt  # Numeric sort
sort -u file.txt  # Unique sort
```

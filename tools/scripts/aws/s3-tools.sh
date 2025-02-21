#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  --copy     Copy objects from source to destination"
    echo "  --compare  Compare objects between two S3 URIs"
    echo "  --bucket   Get bucket statistics"
    echo "  --list     List all buckets"
    echo "  --create   Create a new bucket"
    echo "  --delete   Delete a bucket"
    echo ""
    echo "Options for --copy:"
    echo "  --src_uri      Source S3 URI (e.g., s3://source-bucket/path/to/data/)"
    echo "  --dest_bucket  Destination bucket name (e.g., destination-bucket)"
    echo "  --dryrun       Show what would be copied without actually copying"
    echo ""
    echo "Options for --compare:"
    echo "  --src_uri   Source S3 URI (e.g., s3://source-bucket/path/to/data/)"
    echo "  --dest_uri  Destination S3 URI (e.g., s3://destination-bucket/path/to/data/)"
    echo ""
    echo "Options for --bucket:"
    echo "  --name    Bucket name (e.g., my-bucket)"
    echo "  --size    Show total size of bucket"
    echo "  --count   Show total number of objects"
    echo ""
    echo "Options for --create:"
    echo "  --name    Bucket name to create (e.g., my-new-bucket)"
    echo "  --region  AWS region (default: us-east-1)"
    echo ""
    echo "Options for --delete:"
    echo "  --name     Bucket name to delete"
    echo "  --force    Force deletion of non-empty bucket"
    echo ""
    echo "Examples:"
    echo "  $0 --copy --src_uri s3://source-bucket/path/to/data/ --dest_bucket destination-bucket"
    echo "  $0 --compare --src_uri s3://source-bucket/path/to/data/ --dest_uri s3://destination-bucket/path/to/data/"
    echo "  $0 --bucket --name my-bucket --size --count"
    echo "  $0 --list"
    echo "  $0 --create --name my-new-bucket --region us-west-2"
    echo "  $0 --delete --name my-bucket"
    echo "  $0 --delete --name my-bucket --force"
    exit 1
}

# Function to delete a bucket
delete_bucket() {
    local bucket_name="$1"
    local force="$2"

    # Check if bucket exists
    if ! aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
        echo "Error: Bucket does not exist or you don't have access"
        return 1
    fi

    # Check if bucket is empty (handle "None" output correctly)
    local bucket_contents=$(aws s3api list-objects-v2 --bucket "$bucket_name" --max-items 1 --query 'Contents[].Key' --output text)
    local is_empty=false

    if [ "$bucket_contents" = "None" ] || [ -z "$bucket_contents" ]; then
        is_empty=true
    fi

    if [ "$is_empty" = false ] && [ "$force" != "true" ]; then
        echo "Error: Bucket is not empty. Use --force to delete non-empty bucket"
        return 1
    fi

    echo "Deleting bucket: $bucket_name"

    if [ "$force" = "true" ] && [ "$is_empty" = false ]; then
        echo "Removing all objects from bucket..."
        if ! aws s3 rm "s3://${bucket_name}" --recursive; then
            echo "Error: Failed to remove objects from bucket"
            return 1
        fi
    fi

    if aws s3api delete-bucket --bucket "$bucket_name"; then
        echo "Bucket deleted successfully"
        return 0
    else
        echo "Error: Failed to delete bucket"
        return 1
    fi
}

list_buckets() {
    echo "Listing all S3 buckets:"
    echo "----------------------------------------"
    aws s3api list-buckets --query 'Buckets[].Name' --output table
}

# Function to create a new bucket
create_bucket() {
    local bucket_name="$1"
    local region="${2:-us-east-1}" # Default to us-east-1 if not specified

    # Validate bucket name
    if [[ ! "$bucket_name" =~ ^[a-z0-9][a-z0-9.-]*[a-z0-9]$ ]]; then
        echo "Error: Invalid bucket name. Bucket names must:"
        echo "  - Start and end with a lowercase letter or number"
        echo "  - Contain only lowercase letters, numbers, dots (.), and hyphens (-)"
        echo "  - Be between 3 and 63 characters long"
        return 1
    fi

    echo "Creating bucket: $bucket_name in region: $region"
    if [ "$region" = "us-east-1" ]; then
        # Special case for us-east-1 as it doesn't accept LocationConstraint
        if aws s3api create-bucket --bucket "$bucket_name" 2>/dev/null; then
            echo "Bucket created successfully"
            return 0
        fi
    else
        if aws s3api create-bucket \
            --bucket "$bucket_name" \
            --create-bucket-configuration LocationConstraint="$region" 2>/dev/null; then
            echo "Bucket created successfully"
            return 0
        fi
    fi

    echo "Error: Failed to create bucket. Possible reasons:"
    echo "  - Bucket name already exists"
    echo "  - Invalid region"
    echo "  - Insufficient permissions"
    return 1
}

format_size() {
    local size=$1
    local power=0
    local units=("B" "KB" "MB" "GB" "TB")

    while (($(echo "$size > 1024" | bc -l) == 1 && power < 4)); do
        size=$(echo "scale=2; $size/1024" | bc -l)
        ((power++))
    done

    printf "%.2f %s" $size "${units[$power]}"
}

# Function to get bucket statistics
get_bucket_stats() {
    local bucket_name="$1"
    local show_size="$2"
    local show_count="$3"

    # Verify bucket exists
    if ! aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
        echo "Error: Bucket does not exist or you don't have access"
        exit 1
    fi

    # Get statistics excluding empty folders
    local stats=$(aws s3 ls "s3://${bucket_name}" --recursive | grep -v "/$" | awk '
        BEGIN {count=0; total=0}
        {count++; total+=$3}
        END {print count, total}
    ')
    local count=$(echo $stats | cut -d' ' -f1)
    local size=$(echo $stats | cut -d' ' -f2)

    echo "Bucket: s3://${bucket_name}"
    echo "----------------------------------------"
    if [ "$show_count" = true ]; then
        echo "Total Objects: $count"
    fi
    if [ "$show_size" = true ]; then
        local human_readable_size=$(format_size $size)
        echo "Total Size: $human_readable_size ($size bytes)"
    fi
}

# Function to compare S3 paths
compare_paths() {
    local src_uri="$1"
    local dest_uri="$2"

    echo "Comparing objects between:"
    echo "Source: $src_uri"
    echo "Destination: $dest_uri"
    echo ""

    # Get source statistics
    echo "Analyzing source..."
    src_stats=$(aws s3 ls "$src_uri" --recursive | grep -v "/$" | awk '
        BEGIN {count=0; total=0}
        {count++; total+=$3}
        END {print count, total}
    ')
    src_count=$(echo $stats | cut -d' ' -f1)
    src_size=$(echo $stats | cut -d' ' -f2)

    # Get destination statistics
    echo "Analyzing destination..."
    dest_stats=$(aws s3 ls "$dest_uri" --recursive | grep -v "/$" | awk '
        BEGIN {count=0; total=0}
        {count++; total+=$3}
        END {print count, total}
    ')
    dest_count=$(echo $stats | cut -d' ' -f1)
    dest_size=$(echo $stats | cut -d' ' -f2)

    # Display comparison
    echo ""
    echo "Comparison Results:"
    echo "----------------------------------------"
    echo "Source ($src_uri):"
    echo "  Objects: $src_count"
    echo "  Total Size: $(format_size $src_size) ($src_size bytes)"
    echo ""
    echo "Destination ($dest_uri):"
    echo "  Objects: $dest_count"
    echo "  Total Size: $(format_size $dest_size) ($dest_size bytes)"
    echo "----------------------------------------"

    # Check if they match
    if [ "$src_count" -eq "$dest_count" ] && [ "$src_size" -eq "$dest_size" ]; then
        echo "✓ MATCH: Both locations have identical object count and total size"
        return 0
    else
        echo "✗ MISMATCH: Differences detected in object count or total size"
        return 1
    fi
}

# Function to copy S3 objects
copy_objects() {
    local source_uri="$1"
    local dest_bucket="$2"
    local dryrun="$3"

    # Extract the path from source URI
    local source_path="${source_uri#s3://*/}"
    if [ -z "$source_path" ]; then
        echo "Error: Source path cannot be empty"
        exit 1
    fi

    # Remove trailing slash if exists
    source_path="${source_path%/}"

    # Construct destination URI
    local dest_uri="s3://${dest_bucket}/${source_path}"

    echo "Copying from: $source_uri"
    echo "Copying to: $dest_uri"

    # Verify source exists
    if ! aws s3 ls "$source_uri" &>/dev/null; then
        echo "Error: Source path does not exist or you don't have access"
        exit 1
    fi

    # Verify destination bucket exists
    if ! aws s3api head-bucket --bucket "$dest_bucket" >/dev/null 2>&1; then
        echo "Error: Destination bucket does not exist or you don't have access"
        exit 1
    fi

    # Perform the copy with progress
    echo "Starting copy operation..."
    if aws s3 cp "$source_uri" "$dest_uri" --recursive $dryrun; then
        echo "Copy operation completed successfully"
        return 0
    else
        echo "Error: Copy operation failed"
        return 1
    fi
}

# Initialize variables
COMMAND=""
SOURCE_URI=""
DEST_BUCKET=""
SRC_URI=""
DEST_URI=""
DRYRUN=""
BUCKET_NAME=""
SHOW_SIZE=false
SHOW_COUNT=false
REGION="us-east-1" # Default region
FORCE=false

# Parse command first
case $1 in
--copy | --compare | --bucket | --list | --create | --delete)
    COMMAND="$1"
    shift
    ;;
*)
    echo "Error: First argument must be --copy, --compare, --bucket, --list, --create, or --delete"
    usage
    ;;
--delete)
    if [ -z "$BUCKET_NAME" ]; then
        echo "Error: --name is required for delete command"
        usage
    fi
    delete_bucket "$BUCKET_NAME" "$FORCE"
    ;;
esac

# Parse remaining arguments based on command
while [[ $# -gt 0 ]]; do
    case $1 in
    --src_uri)
        [ "$COMMAND" = "--copy" ] && SOURCE_URI="$2" || echo "Error: --src_uri is only valid with --copy"
        shift 2
        ;;
    --dest_bucket)
        [ "$COMMAND" = "--copy" ] && DEST_BUCKET="$2" || echo "Error: --dest_bucket is only valid with --copy"
        shift 2
        ;;
    --src_uri)
        [ "$COMMAND" = "--compare" ] && SRC_URI="$2" || echo "Error: --src_uri is only valid with --compare"
        shift 2
        ;;
    --dest_uri)
        [ "$COMMAND" = "--compare" ] && DEST_URI="$2" || echo "Error: --dest_uri is only valid with --compare"
        shift 2
        ;;
    --name)
        [ "$COMMAND" = "--bucket" -o "$COMMAND" = "--create" -o "$COMMAND" = "--delete" ] && BUCKET_NAME="$2" || echo "Error: --name is only valid with --bucket, --create, or --delete"
        shift 2
        ;;
    --force)
        [ "$COMMAND" = "--delete" ] && FORCE=true || echo "Error: --force is only valid with --delete"
        shift
        ;;
    --region)
        [ "$COMMAND" = "--create" ] && REGION="$2" || echo "Error: --region is only valid with --create"
        shift 2
        ;;
    --size)
        [ "$COMMAND" = "--bucket" ] && SHOW_SIZE=true || echo "Error: --size is only valid with --bucket"
        shift
        ;;
    --count)
        [ "$COMMAND" = "--bucket" ] && SHOW_COUNT=true || echo "Error: --count is only valid with --bucket"
        shift
        ;;
    --dryrun)
        [ "$COMMAND" = "--copy" ] && DRYRUN="--dryrun" || echo "Error: --dryrun is only valid with --copy"
        shift
        ;;
    --help)
        usage
        ;;
    *)
        echo "Unknown parameter: $1"
        usage
        ;;
    esac
done

# Execute appropriate command
case $COMMAND in
--copy)
    if [ -z "$SOURCE_URI" ] || [ -z "$DEST_BUCKET" ]; then
        echo "Error: Both --src_uri and --dest_bucket are required for copy command"
        usage
    fi
    if [[ ! "$SOURCE_URI" =~ ^s3:// ]]; then
        echo "Error: Source must be a valid S3 URI (s3://...)"
        exit 1
    fi
    copy_objects "$SOURCE_URI" "$DEST_BUCKET" "$DRYRUN"
    ;;
--compare)
    if [ -z "$SRC_URI" ] || [ -z "$DEST_URI" ]; then
        echo "Error: Both --src_uri and --dest_uri are required for compare command"
        usage
    fi
    if [[ ! "$SRC_URI" =~ ^s3:// ]] || [[ ! "$DEST_URI" =~ ^s3:// ]]; then
        echo "Error: Both URIs must be valid S3 URIs (s3://...)"
        exit 1
    fi
    compare_paths "$SRC_URI" "$DEST_URI"
    ;;
--bucket)
    if [ -z "$BUCKET_NAME" ]; then
        echo "Error: --name is required for bucket command"
        usage
    fi
    if [ "$SHOW_SIZE" = false ] && [ "$SHOW_COUNT" = false ]; then
        echo "Error: At least one of --size or --count is required for bucket command"
        usage
    fi
    get_bucket_stats "$BUCKET_NAME" "$SHOW_SIZE" "$SHOW_COUNT"
    ;;
--list)
    list_buckets
    ;;
--create)
    if [ -z "$BUCKET_NAME" ]; then
        echo "Error: --name is required for create command"
        usage
    fi
    create_bucket "$BUCKET_NAME" "$REGION"
    ;;
--delete)
    if [ -z "$BUCKET_NAME" ]; then
        echo "Error: --name is required for delete command"
        usage
    fi
    delete_bucket "$BUCKET_NAME" "$FORCE"
    ;;
*)
    echo "Error: Invalid command"
    usage
    ;;
esac

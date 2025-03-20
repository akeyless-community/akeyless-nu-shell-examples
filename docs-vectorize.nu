#!/usr/bin/env nu

# Get the current directory
let curDir = (pwd)
# Get the data directory
let dataDir = ($curDir | path join "data")
# Get the docs directory
let docsDir = ($dataDir | path join "docs")
# Get the vectorize python script path
let vectorizePythonScript = ($curDir | path join "upload_vector_store.py")
# Change to the docs directory
cd $docsDir
# Get the files to vectorize
let filesToVectorize = (ls **/*.md | where size > 0b)
# Vectorize the files
$filesToVectorize | each { |file|
    # Get the file name
    let fileName = ($file.name | into string)
    # Print progress
    print $"Uploading and Vectorizing file: ($fileName)"
    # Get the file json name
    let fileJsonPath = ($fileName | str replace -a -r '(.+?).md' '$1.json')
    # Get the file json contents
    let fileJsonFull = (open $fileJsonPath)
    # Convert the file json to a raw string (stringify the json object)
    let fileJsonFullRaw = ($fileJsonFull | to json -r | into string)
    # Run the script
    let scriptResults = (^uv run $vectorizePythonScript $fileName $fileJsonFullRaw)
    # Convert the script results to a json object
    let scriptResultsJson = ($scriptResults | from json)
    # Print the script results
    $scriptResultsJson
}

# Change back to the current directory
cd $curDir

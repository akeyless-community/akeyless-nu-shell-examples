#!/usr/bin/env nu

# this file was replaced by the python script upload_vector_store.py

def check_openai_api_key [] {
    if "OPENAI_API_KEY" in $env {
        print $"(ansi green_bold)Success:(ansi reset) OPENAI_API_KEY environment variable is set"
    } else {
        print $"(ansi red_bold)Error:(ansi reset) OPENAI_API_KEY environment variable is not set"
        print $"Please set the environment variable with: (ansi cyan)export OPENAI_API_KEY=your_token_value(ansi reset)"
        exit 1
    }
}

def check_vector_store_id [] {
    if "VECTOR_STORE_ID" in $env {
        print $"(ansi green_bold)Success:(ansi reset) VECTOR_STORE_ID environment variable is set"
    } else {
        print $"(ansi red_bold)Error:(ansi reset) VECTOR_STORE_ID environment variable is not set"
        print $"Please set the environment variable with: (ansi cyan)export VECTOR_STORE_ID=your_vector_store_id(ansi reset)"
        exit 1
    }
}

def upload_file_to_openai [openaiHeaders:list<string> fileFullPath:string] {
    # We have to use curl to upload the file instead of native nu shell or else the file name will not show up in the OpenAI file list
    let max_retries = 5
    let base_wait_time = 1  # Initial wait time in seconds
    
    mut attempts = 0
    while $attempts < $max_retries {
        $attempts = $attempts + 1
        let currentAttempt = $attempts
        
        # Attempt to upload file
        let result = do {
            let fileObject = (^curl -s https://api.openai.com/v1/files -H $"Authorization: Bearer ($env.OPENAI_API_KEY)" -F purpose="assistants" -F $"file=@($fileFullPath)" | from json)
            
            # Check if the response contains an ID
            if "id" in $fileObject {
                let fileId = ($fileObject | get id)
                print $"File ID Created: (ansi green_bold)($fileId)(ansi reset)"
                return $fileId
            } else {
                # No ID in response
                print $"(ansi yellow_bold)Warning:(ansi reset) Failed to get file ID from response on attempt ($currentAttempt)/($max_retries)"
                return null
            }
        } catch {
            print $"(ansi yellow_bold)Warning:(ansi reset) Error uploading file on attempt ($currentAttempt)/($max_retries)"
        }
        
        # If we got a result, return it
        if $result != null {
            return $result
        }
        
        # Calculate exponential backoff time
        if $attempts < $max_retries {
            let wait_time = ($base_wait_time * (2 ** ($attempts - 1)))
            print $"Retrying in ($wait_time) seconds..."
            sleep ($wait_time * 1sec)
        }
    }
    
    # If we get here, we've failed all retries
    print $"(ansi red_bold)Error:(ansi reset) Failed to upload file after ($max_retries) attempts"
    exit 1
}

def add_file_to_vector_store [openaiHeaders:list<string> vectorStoreId:string fileId:string categoryName:string docSlug:string docName:string parentName:string = "none" parentSlug:string = "none" grandParentName:string = "none" grandParentSlug:string = "none"] {
    let docUrl = $"https://docs.akeyless.io/docs/($docSlug)"
    let vectorStoreUrl = $"https://api.openai.com/v1/vector_stores/($vectorStoreId)/files"
    let payload = { file_id: $fileId, attributes: 
        { category: $categoryName, parent_name: $parentName, parent_slug: $parentSlug, grandparent_name: $grandParentName, grandparent_slug: $grandParentSlug, url: $docUrl, doc_name: $docName, doc_type: 'public-docs' } }
    let vectorStoreObject = (http post --content-type "application/json" --headers $openaiHeaders $vectorStoreUrl $payload)
    return $vectorStoreObject
}

check_openai_api_key
check_vector_store_id

let openaiCreds = $"Bearer ($env.OPENAI_API_KEY)"
let openaiHeaders = [("authorization") ($openaiCreds)]
let vectorStoreId = $env.VECTOR_STORE_ID


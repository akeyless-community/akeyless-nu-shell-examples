#!/usr/bin/env nu

# Define API endpoint
let api_endpoint = "api.akeyless.io"
# Define minimum token validity duration
let min_token_validity = 10min

def validate_akeyless_token [token: string] {
    let validateToken = (http post --content-type application/json $"https://($api_endpoint)/validate-token" {token: $token})
    let is_valid = ($validateToken | get is_valid)
    
    if $is_valid {
        let expirationDateString = ($validateToken | get expiration)
        let now = (date now)
        let timeUntilExpiration = ($expirationDateString | into datetime) - $now
        
        if $timeUntilExpiration < $min_token_validity {
            return {
                is_valid: false,
                message: $"Token will expire too soon (in ($timeUntilExpiration)). It must be valid for at least ($min_token_validity).",
                expiration: $expirationDateString,
                time_until_expiration: $timeUntilExpiration
            }
        } else {
            return {
                is_valid: true,
                message: $"Token is valid and will expire in ($timeUntilExpiration).",
                expiration: $expirationDateString,
                time_until_expiration: $timeUntilExpiration
            }
        }
    } else {
        return {
            is_valid: false,
            message: "Token is invalid.",
            expiration: null,
            time_until_expiration: null
        }
    }
}

def get_akeyless_token [] {
    mut input_token = ""
    while true {
        print $"Please enter your Akeyless token:"
        let token_input = (input)
        
        if ($token_input | is-empty) {
            print $"(ansi red_bold)Error:(ansi reset) Token cannot be empty"
            continue
        }
        
        if not ($token_input | str starts-with "t-") {
            print $"(ansi red_bold)Error:(ansi reset) Token must start with 't-'"
            continue
        }
        
        # Validate the token
        let validation_result = (validate_akeyless_token $token_input)
        if not ($validation_result.is_valid) {
            print $"(ansi red_bold)Error:(ansi reset) ($validation_result.message)"
            print "Please try again with a different token."
            continue
        }
        
        print $"(ansi green_bold)Success:(ansi reset) ($validation_result.message)"
        $input_token = $token_input
        break
    }
    return $input_token
}

def check_akeyless_token [] {
    if "AKEYLESS_TOKEN" in $env {
        print $"(ansi green_bold)Success:(ansi reset) AKEYLESS_TOKEN environment variable is set"
        # Validate the existing token
        let validation_result = (validate_akeyless_token $env.AKEYLESS_TOKEN)
        if not ($validation_result.is_valid) {
            print $"(ansi red_bold)Error:(ansi reset) ($validation_result.message)"
            print $"(ansi yellow)Getting a new token...(ansi reset)"
            let input_token = (get_akeyless_token)
            $env.AKEYLESS_TOKEN = $input_token
        } else {
            print $"(ansi green_bold)Success:(ansi reset) ($validation_result.message)"
        }
    } else {
        print $"(ansi yellow)AKEYLESS_TOKEN not found in environment(ansi reset)"
        let input_token = (get_akeyless_token)
        $env.AKEYLESS_TOKEN = $input_token
    }
}

# Run the check
check_akeyless_token

# Get token from environment variable
let token = $env.AKEYLESS_TOKEN

# Create data directory if it doesn't exist
let data_dir = (pwd | path join "data")
if ($data_dir | path exists) == false {
    mkdir $data_dir
}

# List auth methods
let authMethods = (http post --content-type application/json $"https://($api_endpoint)/list-auth-methods" {token: $token} | get auth_methods)

# Describe each auth method and collect results
let authMethods = ($authMethods | each { |method|
    let name = ($method.auth_method_name | into string)
    print $"Processing auth method: ($name)"
    let authMethod = (http post --content-type application/json $"https://($api_endpoint)/get-auth-method" {token: $token, name: $name})
    $authMethod
})

# Save to file
$authMethods | save -f (pwd | path join "data" "akeyless-auth-methods-archive.json")

# List roles
let roles = (http post --content-type application/json $"https://($api_endpoint)/list-roles" {token: $token} | get roles)

# Describe each role and collect results
let roles = ($roles | each { |role|
    let name = ($role.role_name | into string)
    print $"Processing role: ($name)"
    let role = (http post --content-type application/json $"https://($api_endpoint)/get-role" {token: $token, name: $name})
    $role
})

# Save to file
$roles | save -f (pwd | path join "data" "akeyless-roles-archive.json")

# List Targets
let targets = (http post --content-type application/json $"https://($api_endpoint)/list-targets" {token: $token} | get targets)

# Describe each target and collect results
let targets = ($targets | each { |target|
    let name = ($target.target_name | into string)
    print $"Processing target: ($name)"
    let target = (http post --content-type application/json $"https://($api_endpoint)/get-target" {token: $token, name: $name})
    $target
})

# Save to file
$targets | save -f (pwd | path join "data" "akeyless-targets-archive.json")

# List items
let items = (http post --content-type application/json $"https://($api_endpoint)/list-items" {token: $token} | get items)

# Describe each item and collect results
let describedItems = ($items | par-each { |item|
    let name = ($item.item_name | into string)
    print $"Processing item: ($name)"  # Debug line
    let describeItem = (http post --content-type application/json $"https://($api_endpoint)/describe-item" {token: $token, name: $name})
    $describeItem
})

# Save to file
$describedItems | save -f (pwd | path join "data" "akeyless-items-archive.json")

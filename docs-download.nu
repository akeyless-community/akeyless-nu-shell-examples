#!/usr/bin/env nu

def check_readme_api_key [] {
    if "README_API_KEY" in $env {
        print $"(ansi green_bold)Success:(ansi reset) README_API_KEY environment variable is set"
    } else {
        print $"(ansi red_bold)Error:(ansi reset) README_API_KEY environment variable is not set"
        print $"Please set the environment variable with: (ansi cyan)export README_API_KEY=your_token_value(ansi reset)"
        exit 1
    }
}

# Run the checks
check_readme_api_key

# Create data directory if it doesn't exist
let data_dir = (pwd | path join "data" "docs")
if ($data_dir | path exists) == false {
    mkdir $data_dir
}

let creds = $"Basic ($env.README_API_KEY)"
let headers = [("authorization") ($creds)]


let categories = (http get --headers $headers https://dash.readme.com/api/v1/categories)

let cats = ($categories | where reference == false | sort-by order | select title slug)

$cats | each { |catrow|
	let categoryTitle = $catrow.title
	let categorySlug = $catrow.slug
	let url = $"https://dash.readme.com/api/v1/categories/($categorySlug)/docs"
    print $"Processing category: (ansi cyan_bold)($categoryTitle)(ansi reset)"
	let docsFromCategory = (http get --headers $headers $url)

    let catDir = (pwd | path join "data" "docs" ($categoryTitle | into string))
    if ($catDir | path exists) == false {
        mkdir $catDir
    }

	$docsFromCategory | each { |doc|
        # Get the title of the doc
        let docTitle = $doc.title
        # Get the slug of the doc
        let docSlug = $doc.slug
        # Get the hidden status of the doc
        let docHidden = $doc.hidden
        # If the doc is hidden, skip it
        if $docHidden {
            print $"Skipping hidden doc: (ansi yellow_bold)($docTitle)(ansi reset) from category: (ansi cyan_bold)($categoryTitle)(ansi reset)"
            return
        }
        # Get the full doc from the API
        let docUrl = $"https://dash.readme.com/api/v1/docs/($docSlug)"
        print $"Processing doc: (ansi yellow_bold)($docTitle)(ansi reset) from category: (ansi cyan_bold)($categoryTitle)(ansi reset)"
        # Get the full doc from the API
        let docFull = (http get --headers $headers $docUrl)

        # Check if the doc has children
        let hasChildren = ($doc.children | length) > 0
        # If the doc has children, create a directory named after the parent title and do not alter the directory name
        if $hasChildren {
            # Get the children of the doc
            let children = $doc.children
            # Create directory named after the parent title and do not alter the directory name
            let parentDir = (pwd | path join "data" "docs" ($catDir | into string) ($docTitle | into string))
            # Create the parent directory if it doesn't exist
            if ($parentDir | path exists) == false {
                mkdir $parentDir
            }
            # Write the markdown from the child docs to the parent directory
            $children | sort-by order | each { |child|
                # Get the title of the child doc
                let childTitle = $child.title
                # Get the slug of the child doc
                let childSlug = $child.slug
                # Get the hidden status of the child doc
                let childHidden = $child.hidden
                # If the child doc is hidden, skip it
                if $childHidden {
                    print $"Skipping hidden child doc: (ansi yellow_bold)($childTitle)(ansi reset) from parent doc: (ansi cyan_bold)($docTitle)(ansi reset)"
                    return
                }
                # Get the hidden status of the grand children
                let hasGrandChildren = ($child.children | length) > 0
                # If the child doc has grand children, create a directory named after the child title and do not alter the directory name
                if $hasGrandChildren {
                    # Get the grand children of the child doc
                    let grandChildren = $child.children
                    # Create directory named after the child title and do not alter the directory name
                    let grandChildDir = (pwd | path join "data" "docs" ($parentDir | into string) ($childTitle | into string))
                    # Create the grand child directory if it doesn't exist
                    if ($grandChildDir | path exists) == false {
                        mkdir $grandChildDir
                    }
                    $grandChildren | sort-by order | each { |grandChild|
                        # Get the title of the grand child doc
                        let grandChildTitle = $grandChild.title
                        # Get the slug of the grand child doc
                        let grandChildSlug = $grandChild.slug
                        # Get the hidden status of the grand child doc
                        let grandChildHidden = $grandChild.hidden
                        # If the grand child doc is hidden, skip it
                        if $grandChildHidden {
                            print $"Skipping hidden grand child doc: (ansi magenta_bold)($grandChildTitle)(ansi reset) from parent doc: (ansi yellow_bold)($childTitle)(ansi reset)"
                            return
                        }
                        # Get the full doc from the API
                        let grandChildUrl = $"https://dash.readme.com/api/v1/docs/($grandChildSlug)"
                        # Get the full doc from the API
                        let grandChildFull = (http get --headers $headers $grandChildUrl)
                        # Write the markdown from the grand child doc to the grand child directory
                        let grandChildFileName = $"($grandChildSlug).md"
                        # Create the file full path
                        let grandChildFileFullPath = ($grandChildDir | path join $grandChildFileName)
                        # Create the json full path
                        let grandChildJsonFullPath = ($grandChildFileFullPath | str replace -a -r '(.+?).md' '$1.json')
                        # Write the markdown from the grand child doc to the grand child directory
                        $grandChildFull | get body | str replace -a -r '\(doc:([^)]+)\)' '(https://docs.akeyless.io/docs/$1)' | save -f $grandChildFileFullPath
                        let url = $"https://docs.akeyless.io/docs/($grandChildSlug)"
                        let createdAt = $grandChildFull.createdAt
                        let updatedAt = $grandChildFull.updatedAt
                        # Create the json object
                        let json = {
                            "slug": $grandChildSlug,
                            "title": $grandChildTitle,
                            "parent_slug": $childSlug,
                            "parent_title": $childTitle,
                            "grandparent_slug": $docSlug,
                            "grandparent_title": $docTitle,
                            "category_slug": $categorySlug,
                            "category_title": $categoryTitle,
                            "url": $url,
                            "created_at": $createdAt,
                            "updated_at": $updatedAt,
                        }
                        $json | save -f $grandChildJsonFullPath
                    }
                }
                # Get the full doc from the API
                let childUrl = $"https://dash.readme.com/api/v1/docs/($childSlug)"
                # Get the full doc from the API
                let childFull = (http get --headers $headers $childUrl)
                # Write the markdown from the child doc to the parent directory
                let fileName = $"($childSlug).md"
                # Create the file full path
                let childFileFullPath = ($parentDir | path join $fileName)
                # Create the json full path
                let childJsonFullPath = ($childFileFullPath | str replace -a -r '(.+?).md' '$1.json')   
                # Write the markdown from the child doc to the parent directory
                $childFull | get body | str replace -a -r '\(doc:([^)]+)\)' '(https://docs.akeyless.io/docs/$1)' | save -f $childFileFullPath
                let url = $"https://docs.akeyless.io/docs/($childSlug)"
                let createdAt = $childFull.createdAt
                let updatedAt = $childFull.updatedAt
                # Create the json object
                let json = {
                    "slug": $childSlug,
                    "title": $childTitle,
                    "parent_slug": $docSlug,
                    "parent_title": $docTitle,
                    "category_slug": $categorySlug,
                    "category_title": $categoryTitle,
                    "url": $url,
                    "created_at": $createdAt,
                    "updated_at": $updatedAt,
                }
                $json | save -f $childJsonFullPath
            }
        }
        # Write the markdown from the doc to the category directory
        let fileName = $"($docSlug).md"
        # Create the file full path
        let docFileFullPath = ($catDir | path join $fileName)
        # Create the json full path
        let docJsonFullPath = ($docFileFullPath | str replace -a -r '(.+?).md' '$1.json')
        # Write the markdown from the doc to the category directory
        $docFull | get body | str replace -a -r '\(doc:([^)]+)\)' '(https://docs.akeyless.io/docs/$1)' | save -f $docFileFullPath
        let url = $"https://docs.akeyless.io/docs/($docSlug)"
        let createdAt = $docFull.createdAt
        let updatedAt = $docFull.updatedAt
        # Create the json object
        let json = {
            "slug": $docSlug,
            "title": $docTitle,
            "category_slug": $categorySlug,
            "category_title": $categoryTitle,
            "url": $url,
            "created_at": $createdAt,
            "updated_at": $updatedAt,
        }
        $json | save -f $docJsonFullPath
    }
}

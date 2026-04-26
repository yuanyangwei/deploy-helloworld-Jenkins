terraform {
  backend "s3" {
    # We leave these empty! 
    # Jenkins will inject these values during 'terraform init' 
    # using the -backend-config flag.
    bucket       = ""
    key          = ""
    region       = ""
    use_lockfile = true
  }
}

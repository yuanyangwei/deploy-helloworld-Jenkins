terraform {
  backend "s3" {
    # We leave these empty! 
    # Jenkins will inject these values during 'terraform init' 
    # using the -backend-config flag.
    bucket       = "yuanyang-terraform-state-2026"
    key          = "jenkins-practice/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}

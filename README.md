# Cognoma core-service

This repository, under the umbrella of Project Cognoma
(https://github.com/cognoma), holds the source code, under open source
license, of the Terraform configuration files used to manage the infrastructure
for the backend of the Project Cognoma.

## Getting started

Make sure to fork [this repository on
 +GitHub](https://github.com/cognoma/infrastructure "cognoma/infrastructure on
 +GitHub") first.

### Prerequisites

This project directly interacts with the Greene Lab AWS account. To be able
to make any modifications using Terraform you will need to:
1. Be invited to the account.
2. Receive an AWS access key and secret key.

If you would like to contribute to this sub-project but do not have access to
the Greene Lab AWS account please contact @dhimmel.

#### Terraform

[Terraform](https://www.terraform.io/) is a way of encoding infrastructure
configurations into code. Before contributing to this repository you should
have Terraform
[installed](https://www.terraform.io/intro/getting-started/install.html)
and
[understand the basics](https://www.terraform.io/intro/getting-started/build.html).

Terraform will be expecting your AWS credentials to be stored in the
environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

For example you can run Terraform like:
```
AWS_ACCESS_KEY_ID=<your_accss_key> AWS_SECRET_ACCESS_KEY=<your_secrey_key> terraform apply
```
or you can just add them to your terminal's environment like so:
```
export AWS_ACCESS_KEY_ID=<your_accss_key>
export AWS_SECRET_ACCESS_KEY=<your_secrey_key>
```
and run `terraform apply`. Adding those lines to your .bashrc will mean you
never have to export them again.

#### Git Crypt

[Git Crypt](https://github.com/AGWA/git-crypt) is a tool which encrypts
certain files as they are pushed to Github.
In order to be able to unlock files you will need to send your GPG key to an
existing user and have them add you to git-crypt with
```
git-crypt add-gpg-user USERID
```
Once they have done so you can then decrypt all encrypted files with:
```
git-crypt unlock
```
To encrypt a new file or all files matching a pattern add a line like
```
<PATTERN> filter=git-crypt diff=git-crypt
```
to the .gitattributes file and commit that .gitattributes file BEFORE
commiting the file you want to encrypt.


- Terraform - tested with v0.9.1
  - [Install](https://www.terraform.io/intro/getting-started/install.html)
  - [Tutorial](https://www.terraform.io/intro/getting-started/build.html)
- git-crypt - tested with v0.5.0
   - Install Linux: `sudo apt-get -y install git-crypt`
   - Install Mac: `brew install git-crypt`

## Developing

Once all of the prerequisites have been met development can follow the standard
Terraform flow of:
1. Run `terraform plan`.
2. Inspect output.
3. Run `terraform apply`.
4. Correct any errors and repeat.

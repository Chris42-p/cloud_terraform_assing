# Terraform Assignment, Verified by Denis on 29-March-2026.

## Option 1: VPC, two networks, routing, and S3
Instructions are as follows:
| Instructions | Network Diagram |
|--------------|-----------------|
| <img src="opt_1/z_instructions.png" alt="The instructions for the assignment"> | <img src="opt_1/z_network_diagram.png" alt="Network diagram for the assignment"> |

## Implementation. 
Please refer to "opt_1" folder in this file. 

## Testing. 

|description | proof |
|--|--|
|Terraform compiled & resources created |<img src="markdown_assets/worked_terraform_apply.png" alt="Image of terraform executing properly" display="style: block" width="600"/>|
|AWS management console VPC displayed|<img src="markdown_assets/worked_VPC_configured.png" alt="Image of terraform executing properly" display="style: block" width="600"/>|


###  Initalize, Planning and Deploying Terraform 
    terraform init     #download packages 
    terraform plan     #show the design
    terraform apply    #apply the design
    terraform destroy  #delete the infrastructure 

<hr>
<br>
<br>
<br>

## Terraform Installation and Setup Guide: Table of Contents
- [Installing Terraform](#installing-terraform)
  - [Download Terraform](#download-terraform)
  - [Extract Terraform](#extract-terraform)
  - [Add Terraform to PATH Variable](#add-terraform-to-path-variable)
- [Add AWS User Credentials to Terminal](#add-aws-user-credentials-to-terminal)
- [Terraform Commands](#terraform-commands)

## Installing Terraform

### Download Terraform
| Terraform Version | Terraform Link |
| --- | --- |
| Latest Version | https://developer.hashicorp.com/terraform/install#windows |
| All Versions | https://releases.hashicorp.com/terraform |

### Extract Terraform
Right-click the .zip file and select "Extract All".
<br>
<img src="markdown_assets/extract_all.png"
    width="400"
    style="display: block;"
    alt='Right-click the file and click "Extract All"'
/>

### Add Terraform to PATH Variable
1. Press the Windows key or the Windows button (blue square) on the left-hand side.
    <br>
   <img src="markdown_assets/windows_button.png"
       width="400"
       style="display: block;"
       alt="Windows button on the bottom left" />

2. Enter "Edit System Variables" in the search bar to open the panel.
    <br>
   <img src="markdown_assets/edit_env_vars.png"
       width="400"
       style="display: block;"
       alt="Edit system variables in the Windows search menu" />

3. Click on the PATH variable, then click Edit.
    <br>
   <img src="markdown_assets/path_var_edit.png"
       width="400"
       style="display: block;"
       alt="Click the PATH, then click Edit" />

4. Add the Terraform location, then click OK.
    <br>
   <img src="markdown_assets/add_terra_to_vars.png"
       width="400"
       style="display:block;"
       alt="Enter the Terraform extracted folder, click the file navigator at the top, copy the drive and file path, paste it at the end of the list, click OK, and exit the 'Edit System Variables' panel" />

## Add AWS User Credentials to Terminal

1. In IAM, create a user for Terraform.  
   IAM: Identity Access Management - Create users that can access the account.
    <br>
   <img src="markdown_assets/aws_add_user.png"
       width="400"
       style="display: block;"
       alt="AWS Add User" />

2. Give the user a name and enable access to the console.

   **Make sure to enable "Provide user access to AWS Management Console".**
    <br>
   <img src="markdown_assets/aws_user_name_n_CLI_access.png"
       width="200"
       style="display: block;"
       alt="Give the user a name and ensure console access" />

3. In Permissions options, give the user "PowerUser" privilege.

   - Select "Add user to group"

   Click "Create group".
    <br>
   <img src="markdown_assets/aws_permissions_user.png"
       width="200"
       style="display: block;"
       alt="Select to add user to a security group, add the user to a PowerUser group if one does not exist, create one." />

   Create a security group with PowerUser permissions.
    <br>
   <img src="markdown_assets/aws_poweruser.png"
       width="400"
       style="display: block;"
       alt="Select to add user to a PowerUser group" />

4. Place the user credentials into the following format, then paste them into a terminal:

   ```
   $env:AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxxx"
   $env:AWS_SECRET_ACCESS_KEY="yyyyyyyyyyyyyyyyyyyyyyyyyyyy"
   $env:AWS_DEFAULT_REGION="zzzzzzzzz"
   ```

## Terraform Commands

| Terraform Command | Description |
| --- | --- |
| `terraform destroy` | Deletes the infrastructure that was created |
| `terraform plan` | Shows what changes will be made |
| `terraform apply` | Deploys the infrastructure |
<!-- | || -->

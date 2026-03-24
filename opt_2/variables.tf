variable "region" {
  description = "region in which the Guard Duty will be deployed"
  type = string
}

variable "email_list" {
  description = "the list of emails that're going to get notifications from guard duty"
    type = list("string")
}

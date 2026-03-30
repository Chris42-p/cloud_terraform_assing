#---------defaults ------
variable "region" {
  description = "region in which the Guarduty will be deployed in"
  type        = string
}

#---------sns --------
variable "email_list" {
  description = "list of the emails to get the notification"
  type        = list(string)
}

#--------severity-----
variable "severity" {
  description = "AWS defined severity levels"
  type        = list(number)
}

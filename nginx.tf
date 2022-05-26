resource "null_resource" "example" {
    depends_on = [
      azurerm_virtual_machine.main
    ]
    connection {
        type = "ssh"
        user = "testadmin"
        host = azurerm_public_ip.my_public_ip.ip_address
        port = 22
        private_key = "${file("~/.ssh/id_rsa_unencrypted")}"
        timeout = "1m"
        agent = true
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "/bin/bash apt-get install nginx -y"
        ]
    }
}
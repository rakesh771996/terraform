//security group
resource "aws_security_group" "SecurityGroup" {
  name        = "SecurityGroup" 
  description = "Allow security group"
  vpc_id      = "vpc-419e8329"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


//S3
resource "aws_s3_bucket" "merabucketh"{
  bucket = "kyayrbucket"
  
  provisioner "local-exec" {
     command = "aws s3 cp C:/Users/Rakesh/Desktop/tera/rakesh.jpg s3://kyayrbucket/"
  }
}


// Block all public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = "${aws_s3_bucket.merabucketh.id}"

  block_public_acls   = true
  block_public_policy = true
}


// providers
provider "aws" {
  region     = "ap-south-1"
  profile    = "rakesh77_77_77"
}

//veriable
//variable "enter_ur_key_name" {
	//type = string
//	default = "mykey"
//}


//instance
resource "aws_instance"  "myin" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name	= "mykey"
  security_groups =  [ "${aws_security_group.SecurityGroup.name}" ] 
  
provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd git php -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo git clone https://github.com/rakesh771996/terraform.git /var/www/html/"

    ]
  }

}

//print AZ
output  "myoutaz" {
	value = aws_instance.myin.availability_zone
}

//print public IP
output  "my_sec_public_ip" {
	value = aws_instance.myin.public_ip
}


//volume
resource "aws_ebs_volume" "esb2" {
  availability_zone = aws_instance.myin.availability_zone
  size              = 1

  tags = {
    Name = "myebs1"
  }  
}


//attach volume
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.esb2.id
  instance_id = aws_instance.myin.id
}


//print id
output  "myoutebs" {
	value = aws_ebs_volume.esb2.id
}

resource "null_resource" "null1"  {


  depends_on = [
    aws_volume_attachment.EBS_attachment,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Rakesh/Desktop/tera/mykey.pem")
    host     = "${aws_instance.myin.public_ip}"
  }

provisioner "remote-exec" {
    inline = [
	  "sudo mkfs.ext4  /dev/xvdf",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/aniketambasta/aws_task_1.git /var/www/html/"

    ]
  }
  tags = {
    Name = "LinuxWorldos1"
  }
}



// cloud front
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "This is origin access identity"
}


resource "aws_cloudfront_distribution" "imagecf" {
    origin {
        domain_name = "kyayrbucket.s3.amazonaws.com"
        origin_id = "S3-kyayrbucket"




        s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
       
    enabled = true
      is_ipv6_enabled     = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-kyayrbucket"




        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 10
        max_ttl = 30
    }
    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }




    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}
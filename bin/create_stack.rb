#!/usr/bin/env ruby
require 'trollop'
require 'aws-sdk-v1'

@opts = Trollop::options do
  opt :keyname, "Name of the keypair for SSH access", :type => String, :required => true, :short => "k"
  opt :stackname, "Name of the CFN stack to create", :type => String, :required => true, :short => "s"
  opt :template, "Name of the CFN template file", :type => String, :required => true, :short => "t"
  opt :region, "AWS region where the stack will be created", :type => String, :required => true, :short => "r"
  opt :vpc_cidr, "CIDR block used by the new VPC", :type => String, :default => "10.1.0.0/16", :short => "v"
  opt :az1_public_cidr, "CIDR block used by Subnet1", :type => String, :default => "10.1.1.0/24"
  opt :az2_public_cidr, "CIDR block used by Subnet1", :type => String, :default => "10.1.2.0/24"
  opt :az1_private_cidr, "CIDR block used by Subnet2", :type => String, :default => "10.1.32.0/24"
  opt :az2_private_cidr, "CIDR block used by Subnet1", :type => String, :default => "10.1.33.0/24"
  opt :nat_instance_type, "Instance Type of NAT instance", :type => String, :default => "t2.micro"
end

AWS.config(region: @opts[:region])

cfn = AWS::CloudFormation.new

def parameters
  parameters = {
    "KeyName"               => @opts[:keyname],
    "VpcCidrBlock"          => @opts[:vpc_cidr],
    "Az1PublicCidrBlock"    => @opts[:az1_public_cidr],
    "Az2PublicCidrBlock"    => @opts[:az2_public_cidr],
    "Az1PrivateCidrBlock"   => @opts[:az1_private_cidr],
    "Az2PrivateCidrBlock"   => @opts[:az2_private_cidr],
    "NatInstanceType"       => @opts[:nat_instance_type]
  }
  return parameters
end

def template
  file = "./templates/#{@opts[:template]}"
  body = File.open(file, "r").read
  return body
end

cfn.stacks.create(@opts[:stackname], template, parameters: parameters, capabilities: ["CAPABILITY_IAM"])

print "Waiting for stack #{@opts[:stackname]} to complete"

until cfn.stacks[@opts[:stackname]].status == "CREATE_COMPLETE"
  print "."
  sleep 5
end

puts ""

result = %x[./bin/add_NATs_to_default_securitygroup.rb #{@opts[:region]} #{@opts[:stackname]}]
print result

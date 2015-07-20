#!/usr/bin/env ruby

require 'aws-cfn-resources'
AWS.config(region: ARGV[0])

ec2_client = AWS::EC2::Client.new
cfn = AWS::CloudFormation.new
vpc_stack = cfn.stacks["#{ARGV[1]}"]


default_sg_id = vpc_stack.vpc('VPC').security_groups.find { |sg| sg.name == 'default' }.id
instance_sg_id = vpc_stack.security_group('InstanceSecurityGroup').id
nat1_instance_id, nat2_instance_id = vpc_stack.instance('Az1NatInstance').id, vpc_stack.instance('Az2NatInstance').id

print "Modifying Security Groups for instances #{nat1_instance_id} and #{nat2_instance_id}..."

ec2_client.modify_instance_attribute(instance_id: nat1_instance_id, groups: [default_sg_id, instance_sg_id])
ec2_client.modify_instance_attribute(instance_id: nat2_instance_id, groups: [default_sg_id, instance_sg_id])

puts "Complete!"

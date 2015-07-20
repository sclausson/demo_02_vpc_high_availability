require 'aws-cfn-resources'

AWS.config(region: ENV['REGION'])

cfn = AWS::CloudFormation.new
stack = cfn.stacks[ENV['STACK_NAME']]

describe "Verify Stack Resource Creation" do
  
  it "creates a VPC" do
    vpc = stack.vpc('VPC')
    expect(vpc).to exist
  end

  it "creates Az1Public Subnet" do
    subnet = stack.subnet('Az1PublicSubnet')
    expect(subnet.state).to be :available
  end

  it "creates Az2Public Subnet" do
    subnet = stack.subnet('Az2PublicSubnet')
    expect(subnet.state).to be :available
  end

  it "places Az1Public and Az2Public Subnets in different Availability Zones" do
    az1 = stack.subnet('Az1PublicSubnet').availability_zone_name
    az2 = stack.subnet('Az2PublicSubnet').availability_zone_name
    expect(az1).not_to eq az2
  end

  it "creates Az1Private Subnet" do
    subnet = stack.subnet('Az1PrivateSubnet')
    expect(subnet.state).to be :available
  end

  it "creates Az2Private Subnet" do
    subnet = stack.subnet('Az2PrivateSubnet')
    expect(subnet.state).to be :available
  end

  it "places Az1Private and Az2Private Subnets in different Availability Zones" do
    az1 = stack.subnet('Az1PrivateSubnet').availability_zone_name
    az2 = stack.subnet('Az2PrivateSubnet').availability_zone_name
    expect(az1).not_to eq az2
  end

  it "creates an Internet Gateway" do
    igw = stack.internet_gateway('InternetGateway')
    expect(igw).to exist
  end

  it "creats Az1NatInstance" do
    instance = stack.instance('Az1NatInstance')
    expect(instance).to exist
  end

  it "creats Az2NatInstance" do
    instance = stack.instance('Az2NatInstance')
    expect(instance).to exist
  end

  it "attaches both the 'Default' and 'NatInstance' security groups to Az1NatInstance and Az2NatInstance" do
    default_sg = stack.vpc('VPC').security_groups.find { |sg| sg.name == 'default' }
    nat_instance_sg = stack.security_group('InstanceSecurityGroup')
    az1_nat_instance_id = stack.instance('Az1NatInstance').id
    az2_nat_instance_id = stack.instance('Az2NatInstance').id
    expect(default_sg.instances[az1_nat_instance_id]).to exist
    expect(nat_instance_sg.instances[az1_nat_instance_id]).to exist
    expect(default_sg.instances[az2_nat_instance_id]).to exist
    expect(nat_instance_sg.instances[az2_nat_instance_id]).to exist
  end

  it "associates the Public Route Table with the Az1Public Subnet" do
    rt = stack.route_table('PublicRouteTable')
    public_subnet = stack.subnet('Az1PublicSubnet')
    assoc_subnet = rt.associations.find {|assoc| assoc.subnet == public_subnet}
    expect(assoc_subnet).not_to be nil
  end

  it "=>routes internet traffic thru the Internet Gateway" do
    rt = stack.route_table('PublicRouteTable')
    route = rt.routes.find { |r| r.destination_cidr_block == "0.0.0.0/0" }
    igw_id = stack.internet_gateway('InternetGateway').id
    expect(route.internet_gateway.id).to eq igw_id
  end

  it "associates the Public Route Table with the Az2Public Subnet" do
    rt = stack.route_table('PublicRouteTable')
    public_subnet = stack.subnet('Az2PublicSubnet')
    assoc_subnet = rt.associations.find {|assoc| assoc.subnet == public_subnet}
    expect(assoc_subnet).not_to be nil
  end

  it "=>routes internet traffic thru the Internet Gateway" do
    rt = stack.route_table('PublicRouteTable')
    route = rt.routes.find { |r| r.destination_cidr_block == "0.0.0.0/0" }
    igw_id = stack.internet_gateway('InternetGateway').id
    expect(route.internet_gateway.id).to eq igw_id
  end

  it "associates the Az1Private route table with the Az1Private Subnet" do
    rt = stack.route_table('Az1PrivateRouteTable')
    private_subnet = stack.subnet('Az1PrivateSubnet')
    expect(rt.associations.first.subnet).to eq private_subnet
  end

  it "=>routes internet traffic from Az1PrivateSubnet thru the Az1NAT instance" do
    rt = stack.route_table('Az1PrivateRouteTable')
    route = rt.routes.find { |r| r.destination_cidr_block == "0.0.0.0/0" }
    nat_instance = stack.instance('Az1NatInstance')
    expect(route.instance).to eq nat_instance
  end

  it "associates the Az2Private route table with the Az2Private Subnet" do
    rt = stack.route_table('Az2PrivateRouteTable')
    private_subnet = stack.subnet('Az2PrivateSubnet')
    expect(rt.associations.first.subnet).to eq private_subnet
  end

  it "=>routes internet traffic from Az2PrivateSubnet thru the Az2NAT instance" do
    rt = stack.route_table('Az2PrivateRouteTable')
    route = rt.routes.find { |r| r.destination_cidr_block == "0.0.0.0/0" }
    nat_instance = stack.instance('Az2NatInstance')
    expect(route.instance).to eq nat_instance
  end

end
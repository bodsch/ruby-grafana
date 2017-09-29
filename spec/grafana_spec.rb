require 'spec_helper'
require 'rspec'
require 'grafana'

RSpec.configure do |config|
  config.mock_with :rspec
end

describe Grafana do

  before do

    config = {
      debug: false,
      grafana: {
        host: 'localhost',
        port: 3000
      }
    }

    @g  = Grafana::Client.new( config )
    @g.login(user: 'admin', password: 'grafana_admin')
  end

  describe 'Instance' do

    it 'login' do
      expect(@g.login(user: 'admin', password: 'grafana_admin')).to be_truthy
      #ping_session).to be_a(Hash)
    end
  end

#   describe 'Admin' do
#
#     it 'admin_settings' do
#       expect(@g.admin_settings()).to be_a(Hash)
#     end
#
#   end
#
#   describe 'Organisation' do
#
#     it 'get current organisation' do
#       puts @g.current_organization
#     end
#
#     it 'getting users from current organisation' do
#       puts @g.current_organization_users
#     end
#
#
# #     it 'check user' do
# #       r = @g.user( 'foo@bar.com')
# #       expect(r).to be_a(Hash)
# #
# #       puts r
# #
# #       status = r.dig('status')
# #       id = r.dig('id')
# #       name = r.dig('name')
# #
# #       expect(status).to be_a(Integer)
# #       expect(id).to be_a(Integer)
# #     end
# #
# #     it 'add user' do
# #
# # #       @g.login(user: 'admin', password: 'grafana_admin')
# #       r = @g.add_user( user_name:'foo', email: 'foo@bar.com', password: 'pass' )
# #       expect(r).to be_a(Hash)
# #
# #       status = r.dig('status')
# #       id = r.dig('id')
# #       message = r.dig('message')
# #
# #       expect(r).to be_a(Hash)
# #       expect(status).to be_a(Integer)
# #       expect(id).to be_a(Integer)
# #
# #     end
#   end
#

  describe 'Organisations' do

    it 'Create Organisation' do
      r = @g.create_organisation( name: 'Spec Test' )

      expect(r).to be_a(Hash)

      status  = r.dig('status')
      orgId   = r.dig('orgId')
      message = r.dig('name')

      expect(status).to be_a(Integer)
      expect(orgId).to be_a(Integer)
    end

    it 'Search all Organisations' do
      r = @g.all_organizations

      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).equal?(200)
    end

   it 'Get Organisation by Id' do

     r = @g.organization_by_id( 1 )

     expect(r).to be_a(Hash)

     status  = r.dig('status')
     id      = r.dig('id')
     name    = r.dig('name')

     expect(status).to be_a(Integer)
     expect(id).to be_a(Integer)
     expect(name).to be_a(String)
   end

    it 'Get Organisation by Name' do
      r = @g.organization_by_name( 'Spec Test' )

      expect(r).to be_a(Hash)

      status  = r.dig('status')
      id      = r.dig('id')
      name    = r.dig('name')

      expect(status).to be_a(Integer)
      expect(id).to be_a(Integer)
      expect(name).to be_a(String)
      expect(name).equal?('Spec Test')

    end

    it 'Update Organisation' do

      org = @g.organization_by_name('Spec Test')
      id   = org.dig('id')
      name = org.dig('name')

      r = @g.update_organization( organization: 'Spec Test', name: 'Spec+Test' )
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).equal?(200)

      r = @g.update_organization( organization: 'Spec+Test', name: 'Spec Test' )
    end


    it 'Get Users in Organisation' do

      org = @g.organization_by_name('Spec Test')
      id   = org.dig('id')
      name = org.dig('name')

      r = @g.organization_users(id)

      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).equal?(200)
      message = r.dig('message')

      expect(message).to be_a(Array)
      expect(message.size).to be >= 1
    end

    it 'Add User in Organisation' do

      r = @g.add_user_to_organization( organization: 'Spec Test', loginOrEmail: 'foo@bar.com', role: 'Viewer' )

      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).equal?(200)
    end

    it 'Update Users in Organisation' do

      r = @g.update_organization_user( organization: 'Spec Test', loginOrEmail: 'foo@bar.com', role: 'Viewer' ) # @orgId, 2, role: 'Viewer' )

      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).equal?(200)
    end

    it 'Delete User in Organisation' do
      r = @g.delete_user_from_organization( organization: 'Spec Test', loginOrEmail: 'foo@bar.com' )

      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).equal?(200)
    end

    it 'Delete Organisation' do
      r = @g.delete_organisation( name: 'Spec Test' )

      expect(r).to be_a(Hash)

      status = r.dig('status')
      message = r.dig('message')

      expect(status).to be_a(Integer)
      expect(message).to be_a(String)
    end

  end


  describe 'Dashboard' do

    it 'list dashboard' do
      r = @g.dashboard('test')
      expect(r).to be_a(Hash)

      slug = r.dig('slug')
      expect(slug).equal?('test')
    end

    it 'import dashboards from directory' do

      r = @g.import_dashboards_from_directory('/tmp/grafana/dashboards')
      expect(r).to be_a(Hash)

      puts r.find { |x| x.dig('status') }
    end

    it 'dashboards tags' do

      r = @g.dashboard_tags
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).equal?(200)
    end

    it 'home dashboard' do

      r = @g.home_dashboard
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).equal?(200)
    end

    it 'delete dashboard' do

      r = @g.delete_dashboard('test')
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).equal?(200)
    end


  end

end
